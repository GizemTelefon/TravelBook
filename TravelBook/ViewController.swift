//
//  ViewController.swift
//  TravelBook
//
//  Created by Gizem Telefon on 18.12.2023.
//

import UIKit
import MapKit
import CoreLocation   // Kullanıcının lokasyonunu almak için bu kütüphaneyi kullanıyoruz.
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView! // MKMapViewDelegate ve import MapKit i eklememiz gerek bunu kullanabilmek için.
    var locationManager = CLLocationManager() // CLLocationManagerDelegate ve import CoreLocation ı eklememiz gerek bunu kullanabilmek için.
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLocation()
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)) // Başka bir yere tıklayınca klavyenin kapanması için
        view.addGestureRecognizer(tap)
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:))) //* Kullanıcı uzun bastı mı basmadı mı onu anlayacağız.
        gestureRecognizer.minimumPressDuration = 1 // Kaç saniye basılı tutunca çalışacağını seçiyoruz.
        mapView.addGestureRecognizer(gestureRecognizer)
            
        if selectedTitle != "" {   // TableView da eğer seçtiğimiz yer boş değil ise tıkladığımızda o yerin id sini, bilgilerini bize ver demek. Pinli yeri göster demek.
            fetchAndSetSelectedLocation()
        } // Eğer boşsa yani + ya tıklanıldıysa yeni data oluşturacak.
    }
    
    fileprivate func configureLocation() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Konumun verisini ne kadar keskinlikle bulunması için yapıyoruz. kCLLocationAccuracyBest: En iyi tahmini yapar fakat çok pil harcar. kCLLocationAccuracyKilometer: 2 km lik sapma açar ama daha az şarj yer.
        locationManager.requestWhenInUseAuthorization() // Uygulamayı kullanırken konumunu takip etmek için. requestAlwaysAuthorization gerçekten önemli bir sebep varsa kullanılır çünkü kullanıcının her zaman konumunu bilmek önemlidir.
        //locationManager.startUpdatingLocation() // Kullanıcının yerini bununla birlikte almaya başlıyoruz. //* İnfo ya açıklama gir.
        setMyCurrentLocation()
    }
    
    fileprivate func fetchAndSetSelectedLocation() {
        // CoreData
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places") // Core Data üzerinde "Places" entity'sinden veri çekmek için bir sorgu oluştur
        let idString = selectedTitleID!.uuidString // Seçilen yerin UUID'sini string formatına çevir
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString) // Sorguya bir filtre (predicate) ekleyerek sadece seçili yerin verisini çek
        fetchRequest.returnsObjectsAsFaults = false  // Hata ayıklama amaçlı olarak, olası hataları gösterme
        
        do {
            let results = try context.fetch(fetchRequest)   // Sorguyu çalıştır ve sonuçları al
            if results.count > 0 {  // Eğer sonuçlar varsa
                for result in results as! [NSManagedObject] {  // Her bir sonuç üzerinde dön
                    if let title = result.value(forKey: "title") as? String {
                        annotationTitle = title
                        
                        if let subtitle = result.value(forKey: "subtitle") as? String {
                            annotationSubtitle = subtitle
                            
                            if let latitude = result.value(forKey: "latitude") as? Double {
                                annotationLatitude = latitude
                                
                                if let longitude = result.value(forKey: "longitude") as? Double {
                                    annotationLongitude = longitude
                                    
                                    let annotation = MKPointAnnotation() // Bir pin oluşturuyoruz. Bu pinde enlem, boylam, isim ve açıklama görünsün kayıtlı kalsın istiyoruz.
                                    annotation.title = annotationTitle
                                    annotation.subtitle = annotationSubtitle
                                    let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                    annotation.coordinate = coordinate
                                    mapView.addAnnotation(annotation) // Bunu mapView da göster, ekle dedik.
                                    nameText.text = annotationTitle
                                    commentText.text = annotationSubtitle
                                    // Buradan sonrası konumumuz değişse bile pinlediğimiz yer tableView da sabit kalması için yapıyoruz;
                                    //  locationManager.stopUpdatingLocation()
                                    let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                                    let region = MKCoordinateRegion(center: coordinate, span: span)
                                    mapView.setRegion(region, animated: true)
                                }
                            }
                        }
                    }
                    
                }
            }
        } catch {
            print ("error")
        }
    }
    
    
    @objc func dismissKeyboard() { // Başka bir yere tıklayınca klavyenin kapanması için fonksiyon
        view.endEditing(true)
    }
    
    func setMyCurrentLocation (){  // Konumumuzu belirleyip hafızasında tutuyor o an için
        let lat = locationManager.location?.coordinate.latitude;
        let longi = locationManager.location?.coordinate.longitude;
        let location = CLLocationCoordinate2D(latitude: lat!, longitude: longi!)
        // CLLocation: bir enlem ve boylam verir. Biz kullanıcının enlemi boylamını bulmak için "locations[0].coordinate.latitude" kullandık.
        let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025) // Span: Zoom. (0.1 dedik. Ne kadar küçük olursa o kadar zoomlamış oluruz)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began { // Yani basmaya başlaması için o 1 saniye geçmişse
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // Dokunduğu noktanın lokasyonunu alıyouz.
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) //* Noktanın lokasyonunu koordinata çeviriyoruz.
            
            chosenLatitude = touchedCoordinates.latitude  // Kullanıcı her dokunduğunda bu chosenLatitude ve chosenLongitude değişkenleri değişecek.
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()    // Pin oluşturuyoruz. Annotation deniliyor genelde.
            annotation.coordinate = touchedCoordinates   // Annotation' a koordinat veriyoruz.
            annotation.title = nameText.text  // İsmini veriyoruz.
            annotation.subtitle = commentText.text  // Alt başlık veriyoruz.
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {  // MapView yaz çıkanlara bak.
        if annotation is MKUserLocation { // Kullanıcının yerini gösteren pin.
            return nil // Ama kullanıcının yerini değil işaretlediğimiz yeri görmek istiyoruz. Bu yüzden return nil dedik.
        }
        let reUseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reUseId) as? MKMarkerAnnotationView // Yeni bir pin tanımladık.
        
        if pinView == nil { //* Daha bu pinView oluşturulmadıysa, boşsa;
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reUseId) // MKPinAnnotation yazıyordu ama biz bunu MKMarkerAnnotationView ile güncelledik.Çünkü bu kod IOS 16 dan sonra değişti uyarısı aldık.
            pinView?.canShowCallout = true  // canShowCallout: Bir baloncukla ekstra bilgi gösterdiğimiz yer.
            pinView?.tintColor = UIColor.black  // Annotation rengini siyah yaptık.
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) // Detay gösterecek bir buton tanımladık. Yani pindeki info (i) sembolünü tanımladık.
            pinView?.rightCalloutAccessoryView = button // Sağ tarafında gösterilecek görünümde bu button ı göster dedik.
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){ // (i)sembolüne tıklandığında çalışacak fonksiyon
       if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        // Nasıl bir navigasyon yapacaksın = MKLaunchOptionsDirectionsModeKey(Hangi araçla göstereyim) : MKLaunchOptionsDirectionsModeDriving(Arabayla göster)
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            } // CLGeocoder : Koordinatlar ve yerler arasında bağlantı kurmamızı sağlayan bir sınıf. reverseGeocodeLocation: Gitmek istediğim yeri gösteren obje kullnarak. O obje ile navigasyon başlatacağız.
        }
    }
    
    // Save Butonuna tıklandığında kaydedeceği değerlerin olduğu fonksiyon;
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context) // Travel Book içindeki entity ismi Places.
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print ("success")
        } catch {
            print ("error") //TODO: alert ekle
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true) // Bir önceki ViewController'a geri götürüyor.
        
    }
}

