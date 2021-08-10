
import Foundation
import Moya

public enum SupportRequestParams {
    case sendQuestion(message:String, token:String)
    case getQuestion(token:String)
}

extension SupportRequestParams: TargetType {
  // 1
  public var baseURL: URL {
    return URL(string: kBaseURL)!
  }

  // 2
  public var path: String {
    switch self {
        case .sendQuestion:                 return "/support"
        case .getQuestion:                  return "/support"
    }
  }

  // 3
  public var method: Moya.Method {
    switch self {
        case .sendQuestion: return .post
        case .getQuestion: return .get
    }
  }

  // 4
  public var sampleData: Data {
    return Data()
  }

  // 5
  public var task: Task {
    switch self {
        case .sendQuestion(let message, _):
            return .requestParameters(
                parameters: [
                    "message": message as Any].filter({(key: String, value: Any) in if case Optional<Any>.none = value {return false} else {return true}}),
                encoding: URLEncoding.default)

        case .getQuestion:
            return .requestPlain
    }
  }

  // 6
  public var headers: [String: String]? {
    switch self {
        case .sendQuestion(_, let token):
            return ["Content-Type": "application/x-www-form-urlencoded",
                    "Authorization": "Bearer " + token]
        case .getQuestion(let token):
            return ["Content-Type": "application/x-www-form-urlencoded",
                    "Authorization": "Bearer " + token]
        }
    }
    
    public var validationType: ValidationType {
      return .successCodes
    }
}

class SendQuestionSupportRequest:AuthorizationRequest{
    let provider = MoyaProvider<SupportRequestParams>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(), output: NetworkLoggerPlugin.Configuration.defaultOutput, logOptions: .verbose))])
    
    var cancelation:Cancellable?
    func cancel() {
        cancelation?.cancel()
    }

    func run(message:String, completion: @escaping ((_ notes:SupportUserQuestionModel?, _ message:String?)->Void)) {
        cancel()
        guard let accessToken = LoginModel.current?.accessToken else {completion(nil, kLogoutMessage); return}
        cancelation = provider.request(.sendQuestion(message: message, token:accessToken)) { [weak self] result in
           guard let self = self else { return }
           self.cancelation = nil
        
            switch result {
            case .success(let response):
              do {
                  let responseModel = try JSONDecoder().decode(ResponseModel<SupportUserQuestionModel>.self, from: response.data)
                  
                  let jsonData = try response.mapJSON()
                  print(jsonData)
                  
                    if responseModel.success {
                        completion(responseModel.data, responseModel.message)
                    }
                    else{
                        if responseModel.authorization {
                            completion(nil, responseModel.message)
                        }
                        else{
                            AuthorizationRequest.processAuthorizationFaild()
                        }
                    }
              } catch {
                  completion(nil, kDefaultErrorMessage)
              }
            case .failure:
              completion(nil, kDefaultErrorMessage)
            }
        }
    }
}

class GetQuestionSupportRequest:AuthorizationRequest{
    let provider = MoyaProvider<SupportRequestParams>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(), output: NetworkLoggerPlugin.Configuration.defaultOutput, logOptions: .verbose))])
    
    var cancelation:Cancellable?
    func cancel() {
        cancelation?.cancel()
    }

    func run(completion: @escaping ((_ note:[SupportListModel]?, _ message:String?)->Void)) {
        cancel()
        guard let accessToken = LoginModel.current?.accessToken else {completion(nil, kLogoutMessage); return}
        cancelation = provider.request(.getQuestion(token: accessToken)) { [weak self] result in
           guard let self = self else { return }
           self.cancelation = nil
        
            switch result {
            case .success(let response):
              do {
                  let responseModel = try JSONDecoder().decode(ListResponseModel<SupportListModel>.self, from: response.data)
                  
                  let jsonData = try response.mapJSON()
                  print(jsonData)
                  
                if responseModel.success {
                    completion(responseModel.data, responseModel.message)
                }
                else{
                    if responseModel.authorization {
                        completion(nil, responseModel.message)
                    }
                    else{
                        AuthorizationRequest.processAuthorizationFaild()
                    }
                }
              } catch {
                  completion(nil, kDefaultErrorMessage)
              }
            case .failure:
              completion(nil, kDefaultErrorMessage)
            }
        }
    }
}

