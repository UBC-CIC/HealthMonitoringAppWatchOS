/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file contains the business logic, which is the interface to HealthKit.
*/

import Foundation
import HealthKit
import Combine
import CoreLocation


// Use this to print the HTTP request for debugging.
extension URLRequest {
    
    public var curlString: String {
        // Logging URL requests in whole may expose sensitive data,
        // or open up possibility for getting access to your user data,
        // so make sure to disable this feature for production builds!
        #if !DEBUG
        return ""
        #else
        var result = "curl -k "
        
        if let method = httpMethod {
            result += "-X \(method) \\\n"
        }
        
        if let headers = allHTTPHeaderFields {
            for (header, value) in headers {
                result += "-H \"\(header): \(value)\" \\\n"
            }
        }
        
        if let body = httpBody, !body.isEmpty, let string = String(data: body, encoding: .utf8), !string.isEmpty {
            result += "-d '\(string)' \\\n"
        }
        
        if let url = url {
            result += url.absoluteString
        }
        
        return result
        #endif
    }
}

class WorkoutManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    /// - Tag: DeclareSessionBuilder
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
    
    /// - Tag: Publishers
    @Published var heartrate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var distance: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    
    // The app's workout state.
    var running: Bool = false
    
    /// - Tag: TimerSetup
    // The cancellable holds the timer publisher.
    var start: Date = Date()
    var cancellable: Cancellable?
    var accumulatedTime: Int = 0
    
    let locationManager = CLLocationManager()
    let userDefaults = UserDefaults()
    var clientID: String?
    var lastUpdateTime: Int = 0
    // Set up and start the timer.
    func setUpTimer() {
        start = Date()
        cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedSeconds = self.incrementElapsedTime()
            }
    }
    
    // Calculate the elapsed time.
    func incrementElapsedTime() -> Int {
        let runningTime: Int = Int(-1 * (self.start.timeIntervalSinceNow))
        return self.accumulatedTime + runningTime
    }
    

    // Request authorization to access HealthKit and CoreLocation.
    func requestAuthorization() {
        clientID = userDefaults.string(forKey: "deviceID")
        if(clientID == nil){
            clientID = UUID().uuidString
            userDefaults.set(clientID, forKey: "deviceID")
        }
        
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestLocation()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.startUpdatingLocation()
        log(logMessage: "setup finished")
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }
    
    // Callback for location update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for item in locations{
            print(item.coordinate.latitude)
            DispatchQueue.main.async {
                self.latitude = item.coordinate.latitude
                self.longitude = item.coordinate.longitude
            }
        }
    }
    
    //Callback for location error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    //Callback for permission response
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager,didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
              case .restricted, .denied:
                 // Disable your app's location features
                 //disableMyLocationBasedFeatures()
                 log(logMessage: "restricted denied")
                 break
                    
              case .authorizedWhenInUse:
                 // Enable your app's location features.
                 //enableMyLocationFeatures()
                log(logMessage: "authorized")
                 break
                    
              case .authorizedAlways:
                 // Enable or prepare your app's location features that can run any time.
                 //enableMyAlwaysFeatures()
                log(logMessage: "authorized always")
                 break
                    
              case .notDetermined:
                log(logMessage: "not determined")
                 break
           }
    }

    
    // Provide the workout configuration.
    func workoutConfiguration() -> HKWorkoutConfiguration {
        /// - Tag: WorkoutConfiguration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        return configuration
    }
    
    // Start the workout.
    func startWorkout() {
        // Start the timer.
        
        setUpTimer()
        self.running = true
        
        // Create the session and obtain the workout builder.
        /// - Tag: CreateWorkout
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
            builder = session.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }
        
        // Setup session and builder.
        session.delegate = self
        builder.delegate = self
        
        // Set the workout builder's data source.
        /// - Tag: SetDataSource
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: workoutConfiguration())
        
        // Start the workout session and begin data collection.
        /// - Tag: StartSession
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            // The workout has started.
        }
    }
    
    // MARK: - State Control
    func togglePause() {
        // If you have a timer, then the workout is in progress, so pause it.
        if running == true {
            self.pauseWorkout()
        } else {// if session.state == .paused { // Otherwise, resume the workout.
            resumeWorkout()
        }
    }
    
    func pauseWorkout() {
        // Pause the workout.
        session.pause()
        // Stop the timer.
        cancellable?.cancel()
        // Save the elapsed time.
        accumulatedTime = elapsedSeconds
        running = false
    }
    
    func resumeWorkout() {
        // Resume the workout.
        session.resume()
        // Start the timer.
        setUpTimer()
        running = true
    }
    
    func endWorkout() {
        // End the workout session.
        session.end()
        cancellable?.cancel()
    }
    
    func resetWorkout() {
        // Reset the published values.
        DispatchQueue.main.async {
            self.elapsedSeconds = 0
            self.activeCalories = 0
            self.heartrate = 0
            self.distance = 0
            self.latitude = 0
            self.longitude = 0
        }
    }
    
    func simpleGetUrlRequest(url : URL){
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            print("The response is : ",String(data: data, encoding: .utf8)!)
            //print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) as Any)
        }
        task.resume()
    }

    func getISOString() -> String {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sss"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let iso8601String = dateFormatter.string(from: Date()) + "Z"
        return iso8601String
    }
    
    func getOSVersion() -> String {
        let os = ProcessInfo().operatingSystemVersion
        return "watchOS " + String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    /**
                Sends a PUT request to a RestAPI that sends health data to the backend.
     */
    func simplePostRequestWithParamsAndErrorHandling(){
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        let session = URLSession(configuration: configuration)
        let url = URL(string: Constants.apigateway)
        var request = URLRequest(url: url!)
        
        request.addValue(Constants.apikey, forHTTPHeaderField: "x-api-key")
        
        request.httpMethod = "PUT"
        //print("\n")
        let data: [String: Any] = [
            "latitude": self.latitude,
            "longitude": self.longitude,
            "heart_rate": self.heartrate,
            "deviceID": self.clientID!,
            "deviceOS": getOSVersion(),
            "time": getISOString(),
        ]
        //This is specified by APIGateway
        let parameters: [String: Any] = [
            "Data": data,
            "PartitionKey": "string",
            "StreamName": "teststream1"
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
        }
        //Print the request using the URL extension above for debugging
        //print("\(request.curlString)")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            if error != nil || data == nil {
                print("Client error!")
                return
            }
//            let resp = response as? HTTPURLResponse
//
//            print("response : ", resp?.statusCode)
//            print(resp?.allHeaderFields)
//            print(resp?.description)
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Oops!! there is server error!")
                return
            }
            
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("response is not json")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                print("The Response is : ",json)
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
        })
        
        task.resume()
    }
    // MARK: - Update the UI
    // Update the published values.
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        let currentTime = Int(Date().timeIntervalSince1970)
        log(logMessage: String(currentTime))
        if(currentTime > lastUpdateTime + 10){
            lastUpdateTime = currentTime
            simplePostRequestWithParamsAndErrorHandling()
        }
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                /// - Tag: SetLabel
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                self.heartrate = roundedValue
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
                self.activeCalories = Double( round( 1 * value! ) / 1 )
                return
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meterUnit = HKUnit.meter()
                let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                self.distance = roundedValue
                return
            default:
                return
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // Wait for the session to transition states before ending the builder.
        /// - Tag: SaveWorkout
        if toState == .ended {
            print("The workout has now ended.")
            builder.endCollection(withEnd: Date()) { (success, error) in
                self.builder.finishWorkout { (workout, error) in
                    // Optionally display a workout summary to the user.
                    self.resetWorkout()
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

func log(logMessage: String, functionName: String = #function) {
    print("\(functionName): \(logMessage)")
}


// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            /// - Tag: GetStatistics
            let statistics = workoutBuilder.statistics(for: quantityType)
            //log(logMessage: "here")
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}
