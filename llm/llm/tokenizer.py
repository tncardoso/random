class SimpleByteEncoding:
    """
    Tokenizer that encodes individual bytes.
    """

    def encode(self, content):
        return list(bytes(content, "utf8"))

    def decode(self, idx):
        """
        Decode array of indices into string. Since models work on a byte
        level, it can generate invalid utf-8. If this happens, bytes
        are ignored.
        """
        
        return bytes(idx).decode("utf8", errors="ignore")

    @property
    def vocab_size(self):
        return 256

if __name__ == "__main__":
    t = SimpleByteEncoding()
    idx = t.encode("i love pizzá")
    print(idx)
    print(t.decode(idx))
    print(t.vocab_size)
