import os
from dataclasses import dataclass
import numpy as np
import tinygrad.nn as nn
from tinygrad.tensor import Tensor
from tinygrad.helpers import dtypes
from tinygrad.nn import optim
from tinygrad.nn.state import get_parameters
import llm.gpt as gpt
from llm.tokenizer import SimpleByteEncoding

@dataclass
class TrainingArgs:
    lr: float = 1e-3
    eval_iters: int = 10
    eval_each: int = 100

def sample_batch(args, data):
    idx = np.random.randint(0, data.shape[0] - args.context_size, (args.batch_size,))
    x = Tensor.stack([data[i:i+args.context_size] for i in idx])
    y = Tensor.stack([data[i+1:i+args.context_size+1] for i in idx])
    return x, y

def estimate_loss(training_args, args, model, data_train, data_val):
    eval_iters = 10
    res = {}

    for split in ["train", "val"]:
        losses = []
        data = data_train if split == "train" else data_val
        for i in range(training_args.eval_iters):
            x, y = sample_batch(args, data)
            _, loss = model(x, y)
            losses.append(loss.numpy())
        losses = np.array(losses)
        res[split] = losses.mean()

    return res


def main():
    gpu = False
    tok = SimpleByteEncoding()

    data_raw = open("data.txt", "r").read()
    data = Tensor(tok.encode(data_raw), dtype=dtypes.int32, requires_grad=False)
    if gpu:
        data.gpu()

    n = int(0.9*data.shape[0])
    data_train = data[:n]
    data_val = data[:]

    training_args = TrainingArgs()
    args = gpt.Args()

    print("data train: %d"%(data_train.shape[0]))
    x, y = sample_batch(args, data_train)

    model = gpt.SimpleGPT(args)
    
    if gpu:
        params = get_parameters(model)
        [x.gpu() for x in params]

    with Tensor.train():
        opt = optim.AdamW(model.parameters(), lr=training_args.lr)
        for step in range(1):
            xb, yb = sample_batch(args, data_train)

            logits, loss = model(xb, yb)
            opt.zero_grad()
            loss.backward()
            opt.step()
            print(step, loss.numpy())

            if step % training_args.eval_each == 0:
                print(estimate_loss(training_args, args,
                                    model,
                                    data_train, data_val))

    gen = model.generate(x, 300).numpy()[0]
    print("== generating text ==")
    print(gen)
    print(tok.decode(gen))


if __name__ == "__main__":
    main()
