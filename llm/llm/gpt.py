import numpy as np
from dataclasses import dataclass
import tinygrad.nn as nn
from tinygrad.tensor import Tensor
from tinygrad.helpers import dtypes
from tinygrad.nn.state import get_parameters
from tinygrad.jit import TinyJit
from tqdm import tqdm

@dataclass
class Args:
    context_size: int = 256
    vocab_size: int = 256
    batch_size: int = 4
    embedding_size: int = 512
    ffw_embedding_size: int = 4 * 512  # 4 * embedding_size
    block_layers: int = 6
    heads: int = 8
    head_size: int = 64                # embedding_size // heads
    dropout: float = 0.2


class AttentionHead:
    """
    Single head of self-attention. This is the simple, readable implementation.
    Everything could be computed at once at MultiHeadAttention.
    """

    def __init__(self, args: Args):
        self.args = args
        self.head_size = args.head_size

        # They key vector that is learned can be seen as answering the question:
        # What content do I have?
        self.key = nn.Linear(args.embedding_size, args.head_size, bias=False)
        # The query vector that is learned can be seen as answering the question:
        # What am I looking for?
        self.query = nn.Linear(args.embedding_size, args.head_size, bias=False)
        # The value vector represents the token value that is actually
        # output. Can be seen as the token's "private information" that could
        # be also learned. This allows for emitting a different value for a token.
        self.value = nn.Linear(args.embedding_size, args.head_size, bias=False)

    def __call__(self, x: Tensor):
        batch_size, time_size, embedding_size = x.shape
        q = self.query(x)    # (batch_size, time_size, head_size)
        k = self.key(x)      # (batch_size, time_size, head_size)

        # Lower triangular matrix. Used to allow attention only between past tokens
        tril = Tensor.tril(Tensor.ones(time_size, time_size))

        # We use dot(key, query) to find alignment between tokens in context.
        # The more aligned, the more important the connection between this tokens is.
        # Only the last two dimensions should be transposed, since first is batch.
        # (batch_size, time_size, head_size) @ (batch_size, head_size, time_size)
        weights = q @ k.transpose(-2, -1) # (batch_size, time_size, time_size)
        # Scaled attention. Divide by sqrt(head_size).
        # Better variance -> improve softmax behavior.
        weights = weights * (self.head_size ** -0.5)
        # Decoder block.
        # masked_fill(tril == 0, float(-inf))
        weights = tril.where(weights, float("-inf"))
        weights = Tensor.softmax(weights, -1)
        weights = weights.dropout(self.args.dropout)
        
        # Apply the attention to token values.
        v = self.value(x)    # (batch_size, time_size, head_size)
        return weights @ v   # (batch_size, time_size, head_size)
        

class MultiHeadAttention:
    """
    Implements a Multi Head Attention, which is the concatenation
    of multiple Attention Heads.
    """

    def __init__(self, args: Args):
        self.args = args
        self.heads = [AttentionHead(args) for _ in range(args.heads)]
        self.projection = nn.Linear(args.embedding_size, args.embedding_size)

    def __call__(self, x: Tensor) -> Tensor:
        out = Tensor.cat(*[h(x) for h in self.heads], dim=-1)
        out = self.projection(out)
        out = out.dropout(self.args.dropout)
        return out
        

class FeedForward:
    """
    Simple feed forward layer with non linearity.
    """

    def __init__(self, args: Args):
        self.args = args
        self.linear = nn.Linear(args.embedding_size, args.ffw_embedding_size)
        self.projection = nn.Linear(args.ffw_embedding_size, args.embedding_size)

    def __call__(self, x: Tensor) -> Tensor:
        out = self.linear(x).gelu()
        out = self.projection(out)
        out = out.dropout(self.args.dropout)
        return out

class TransformerBlock:
    def __init__(self, args: Args):
        self.sa = MultiHeadAttention(args)
        self.ffwd = FeedForward(args)
        self.ln1 = nn.LayerNorm(args.embedding_size)
        self.ln2 = nn.LayerNorm(args.embedding_size)

    def __call__(self, x: Tensor) -> Tensor:
        # LayerNorm is applied before the SA/FFWD, this is different from the paper
        # Attention is All You Need
        # sum x = residual connection
        x = x + self.sa(self.ln1(x))     # communication between tokens / nodes
        x = x + self.ffwd(self.ln2(x))   # computation
        return x

class SimpleGPT:
    """
    Simple transformer architecture.

    References:
    [Let's build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY)
    [Attention is all you need](https://arxiv.org/abs/1706.03762)
    """
    
    def __init__(self, args: Args):
        super().__init__()
        self.args = args

        self.token_embedding = nn.Embedding(args.vocab_size, args.embedding_size)
        # Positional encoding is important because Attention operates only on
        # sets. Since there is no position information, wee need to encode it.
        self.position_embedding = nn.Embedding(args.context_size, args.embedding_size)

        self.blocks = [TransformerBlock(args) for _ in range(args.block_layers)]
        self.ln = nn.LayerNorm(args.embedding_size)
        self.lm_head = nn.Linear(args.embedding_size, args.vocab_size)

    def parameters(self):
        return get_parameters(self)

    @TinyJit
    def __call__(self, idx, y=None):
        batch_size, time_size = idx.shape
        
        token_embeddings = self.token_embedding(idx)
        # this broadcast is falling in tinygrad, explicit setting the values
        positions = Tensor.stack(batch_size * [Tensor.arange(time_size)])
        position_embeddings = self.position_embedding(positions)
        encoded = token_embeddings + position_embeddings
        x = encoded.sequential(self.blocks)
        x = self.ln(x)
        logits = self.lm_head(x)

        if y is None:
            loss = None
        else:
            batch_size, time_size, vocab_size = logits.shape
            logits_calc = logits.reshape(batch_size*time_size, vocab_size)
            targets = y.reshape(batch_size*time_size)
            loss = logits_calc.sparse_categorical_crossentropy(targets)

        return logits, loss

    def generate(self, idx, max_tokens, progress=True):
        rng = range(max_tokens)
        if progress: rng = tqdm(rng)
        for _ in rng:
            idx_crop = idx[:, -self.args.context_size:]
            logits, loss = self(idx_crop)
            logits_last_step = logits[:, -1, :]
            probs = logits_last_step.softmax(axis=-1).numpy()

            idx_next = []
            for row in range(probs.shape[0]):
                idx_next.append(np.random.choice(len(probs[row]), size=(1,), p=probs[row]))
            idx_next = Tensor(idx_next, dtype=dtypes.int32)

            # truncate execution graph
            idx = idx.cat(idx_next, dim=1).realize()
        return idx
