//
//  ViewController.swift
//  AsyncAndAwaitConcurrency
//
//  Created by 3rabApp-oday on 13/02/2023.
//

import UIKit

class ViewModel {
    
    //test
    
    func loadData(){
        
        Task{
            do{
                let data = try await loadTodo(with: 1)
                print(data)
            }catch{
                print(error)
            }
        }
    }
    
    private func loadTodo(with id:Int)  async throws -> Data {
        
        let (data,_) = try await URLSession.shared.data(from: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!)
        return data
    }
    
}
c
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - call semaphore
        //i put it on background to not block main thread untill i end
        DispatchQueue.global().async {
            do {
                let data    = try self.getData(from: "www.google.com")
                let image   = try self.getImageFrom(data: data)
                print(image)
                
            }catch{
                print(error)
            }
        }
        
        
        //MARK: - call Async func from out ( without use antoher async func )
        
        //using TASK to call Async func
        
        Task{
            let resultOfMultiply = await multiplyNumbers(a: 2, b: 2)
            print(resultOfMultiply)
        }
    }

    
    //MARK: - Apply Async Func with Semaphore
    /*
     --------------------------Make Async Code To Work Sync By Using Semaphore-------------------------------
     we need to use or apply it when we have more than function and every One is Depend on other... so i can not to move to next step untill finish the first
     - every (wait) must have one (signal)
     */
    
    func getData(from url:String) throws -> Data{

        let semaPhore = DispatchSemaphore(value: 0) // create semaphore to make this code sync
        
        var data:Data?
        
        DispatchQueue.global().async {
            data = Data()
            semaPhore.signal() // must send signal .. because i awaited untill it send
        }
        
        _ = semaPhore.wait(timeout: .distantFuture) // wait adn don't return untill signal it recieve....parameter mean wait for some time and infinite time
        if let data = data {
            return data // will not excute untill the background i end
        }
        
        throw AppError.noData // throw Error if not successed
    }
    
    
    
    func getImageFrom(data:Data) throws -> UIImage {
        
        let semaphore = DispatchSemaphore(value: 0) // create semaphore
        var image:UIImage?
        
        
        DispatchQueue.global().async {
            image = UIImage()
            semaphore.signal() // send signal to continue
        }
        _ = semaphore.wait(timeout: .distantFuture) // wait untill u recievce signal
        
        if let image = image {
            return image // return image
        }
        throw AppError.noImage //throw error
        
    }
    
    
    //MARK: -  Use modern Concurrency ( Async - Await)
    
    
    //create async function by keyword async
    func sum (a:Int,b:Int) async -> Int {
        return a + b
    }
    
    // create another async func
    // call the first func on it ....... await mean ( dont go to next line or excute any code untill the first func is finished )
    func multiplyNumbers(a:Int,b:Int) async -> Int {
        let resultOFSumFunc = await sum(a: 2, b: 2)
        return a * resultOFSumFunc
    }
  
}


enum AppError:Error{
    case noData , noImage
}


extension URLSession {
    
    func data(from url:URL) async throws -> (Data,URLResponse){
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data , let response = response else {
                    continuation.resume(throwing: AppError.noData)
                    return
                }
                continuation.resume(returning: (data , response))
                return
            }
            .resume()
        })
    }
    
}
