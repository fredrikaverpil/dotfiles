#!/bin/bash -ex

go install golang.org/dl/gotip@latest
go install golang.org/x/tools/cmd/godoc@latest
go install github.com/lotusirous/gostdsym/stdsym@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install golang.org/x/tools/gopls@latest
