module Vaultez
  class Error                < StandardError; end
  class NotAuthenticatedError < Error; end
  class AuthenticationError  < Error; end
  class NotFoundError        < Error; end
  class ApiError             < Error; end
end
