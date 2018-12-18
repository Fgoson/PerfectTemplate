//
//  NetworkServerManager.swift
//  PerfectTemplate
//
//  Created by honpe on 2018/12/12.
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

open class NetworkServerManager {
    
    fileprivate var server: HTTPServer
    
    internal init(root: String, port: UInt16, routesArr: Array<Dictionary<String, Any>>) {
        
        server = HTTPServer.init() //创建HTTPServer服务器
        
        for dict: Dictionary in routesArr {
            
            let baseUri : String = dict["url"] as! String //跟地址
            
            let method : String = dict["method"] as! String //方法
            
            var routes = Routes.init(baseUri: baseUri) //创建路由器
            
            let httpMethod = HTTPMethod.from(string: method)
            
            configure(routes: &routes, method: httpMethod) //注册路由
            
            server.addRoutes(routes) //路由添加进服务
            
        }
        
        server.serverName = "localhost" //服务器名称
        
        server.serverPort = port //端口
        
        server.documentRoot = root //根目录
        
        server.setResponseFilters([(Filter404(), .high)]) //404过滤
        
    }
    
    
    //MARK: 开启服务
    
    open func startServer() {
        
        do {
            
            print("启动HTTP服务器")
            
            try server.start()
            
        } catch PerfectError.networkError(let err, let msg) {
            
            print("网络出现错误：\(err) \(msg)")
            
        } catch {
            
            print("网络未知错误")
            
        }
    }
    
    //MARK: 注册路由
    
    fileprivate func configure(routes: inout Routes,method: HTTPMethod) {
        
        routes.add(method: .get, uri: "/selectUserInfor") { (request, response) in
            
            let path = request.path
            
            print(path)
            
            let jsonDic = DataBaseManager().mysqlGetHomeDataResult()//["hello": "world"]
            
            let jsonString = self.baseResponseBodyJSONData(code: 200, message: "成功", data: jsonDic)
            
            response.setBody(string: jsonString) //响应体
            
            response.completed() //响应
            
        }
    }
    
    //MARK: 通用响应格式
    
    func baseResponseBodyJSONData(code: Int, message: String, data: Any!) -> String {
        
        var result = Dictionary<String, Any>()
        
        result.updateValue(code, forKey: "code")
        
        result.updateValue(message, forKey: "message")
        
        if (data != nil) {
            
            result.updateValue(data, forKey: "data")
            
        }else{
            
            result.updateValue("", forKey: "data")
            
        }
        
        guard let jsonString = try? result.jsonEncodedString() else {
            
            return ""
            
        }
        
        return jsonString
        
    }
    
    //MARK: 404过滤
    
    struct Filter404: HTTPResponseFilter {
        
        func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            
            callback(.continue)
            
        }
        
        func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            
            if case .notFound = response.status {
                
                response.setBody(string: "404 文件\(response.request.path)不存在。")
                
                response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
                
                callback(.done)
                
            } else {
                
                callback(.continue)
                
            }
            
        }
    }
}
