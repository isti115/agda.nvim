Status = {
  EMPTY = 'Empty' ,
  READY = 'Ready' ,
}

-- From: https://github.com/agda/agda/blob/2bab72d99ae3330cbf3a94450a647158838a1d1b/src/full/Agda/Interaction/Base.hs#L416
Rewrite = {
  AS_IS        = 'AsIs'         ,
  INSTANTIATED = 'Instantiated' ,
  HEAD_NORMAL  = 'HeadNormal'   ,
  SIMPLIFIED   = 'Simplified'   ,
  NORMALISED   = 'Normalised'   ,
}

-- From: https://github.com/agda/agda/blob/2bab72d99ae3330cbf3a94450a647158838a1d1b/src/full/Agda/Interaction/Base.hs#L419
ComputeMode = {
  DEFAULT_COMPUTE   = 'DefaultCompute'  ,
  HEAD_COMPUTE      = 'HeadCompute'     ,
  IGNORE_ABSTRACT   = 'IgnoreAbstract'  ,
  USE_SHOW_INSTANCE = 'UseShowInstance' ,
}

return {
  ComputeMode = ComputeMode ,
  Rewrite     = Rewrite     ,
  Status      = Status      ,
}
