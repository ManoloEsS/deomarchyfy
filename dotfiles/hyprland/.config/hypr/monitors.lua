-- Physical monitor layout and workspace assignments.

hl.monitor({
  output = "desc:Acer Technologies ED340CU J0 54520961D3W01",
  mode = "preferred",
  position = "0x0",
  scale = "auto",
})

hl.monitor({
  output = "desc:Samsung Electric Company LF24T35 HCNR501668",
  mode = "preferred",
  position = "-1080x0",
  scale = "auto",
  transform = 1,
})

hl.workspace_rule({
  workspace = "1",
  monitor = "desc:Samsung Electric Company LF24T35 HCNR501668",
})

hl.workspace_rule({
  workspace = "2",
  monitor = "desc:Acer Technologies ED340CU J0 54520961D3W01",
  default = true,
})
