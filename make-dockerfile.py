#!/bin/env python3

suffix = []
with open("Dockerfile.in") as f:
    f = iter(f)
    for line in f:
        if line.startswith("## "):
            for line in f:
                if line.strip() == "## end":
                    suffix = list(f)
        else:
            print(line.strip())

print("## commands from install.sh\n")

with open("install.sh") as f:
    script = f.readlines()

lines = []
start = False
for line in script:
    line = line.strip()
    if line.startswith("#") or not line:
        if line.startswith("## "):
            if start:
                print("RUN <<EOF")
                print("  source ./env.sh")
                for l in lines: print("  " + l)
                print("EOF")
            lines = []
            start = True
            print()
            print(line.strip())
        continue
    lines.append(line)

print("\n\n## suffix from Dockerfile.in")
for l in suffix: print(l.strip())
