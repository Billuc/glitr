/// Errors that may happen when using glitr_wisp
pub type AppError {
  DBError(message: String)
  DecoderError(message: String)
  InternalError(message: String)
}
