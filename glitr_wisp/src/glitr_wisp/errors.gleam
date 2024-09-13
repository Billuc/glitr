pub type AppError {
  DBError(message: String)
  DecoderError(message: String)
  InternalError(message: String)
}
