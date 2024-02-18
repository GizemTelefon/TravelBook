//
//  ListViewController.swift
//  TravelBook
//
//  Created by Gizem Telefon on 18.12.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData() // Lokasyon listesini çek
    }
    override func viewWillAppear(_ animated: Bool) {  // "viewDidLoad" bir kere çağrılırken "viewWillAppear" her bu görünüm göründüğünde çağrıldığı için burada yapıyoruz.
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData() { // Core Data'dan verileri bu fonksiyonla çekiyoruz.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places") // Fetch: Tut getir demek. Önce bunu oluşturuyoruz.
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                self.titleArray.removeAll(keepingCapacity: false)  // Kapasiteyi tutma diyoruz
                self.idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {  // Tek bir result'a ulaşmak için yaptık. Core Data model objesi : NSManagedObject
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID { // Birden fazla isim olabilir o yüzden id ekledik burada. Bunu ileride kullanacağız.
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
        } catch {
            print ("error")
        }
        
    }
    
    @objc func addButtonClicked() { // Bu func tableView da dediğimiz yeri göstermeyi sağlıyor.
        chosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    // TableView Kodları: "numberOfRowsInSection" ve "cellForRowAt"
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell ()
        var content = cell.defaultContentConfiguration()
        content.text = titleArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    // TableView da bir sekmeye tıklandığındaki kodlar: "didSelectRowAt" ve "prepareForSegue"
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenTitleId = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleId
        }
    }
    // Table View'da sola kaydırınca "delete' yapmak için fonksiyon
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { // Eğer kullanıcı sola kaydırarak hücreyi silmeyi seçtiyse bu bloğa gir.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate // AppDelegate sınıfına erişmek için bir referans oluşturduk. CoreData işlemlerini bu referans üzerinden gerçekleştireceğiz.
            let context = appDelegate.persistentContainer.viewContext // CoreData'nin temel işlem birimi olan "context" nesnesini oluştur. Veritabanı işlemleri bu context üzerinden yapılır.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places") // CoreData'dan veri çekmek için oluşturduk. Bu, "Places" adlı entity'den veri almak için kullanılır.
            let idString = idArray[indexPath.row].uuidString // Silinecek verinin benzersiz kimliğini (UUID) alır ve bir stringe dönüştürür.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) // Fetch request'e, sadece belirli bir kimliğe sahip olan veriyi alması için bir filtre eklenir.
            fetchRequest.returnsObjectsAsFaults = false
            do {   // Fetch request'i çalıştırır ve belirtilen filtre ile eşleşen sonuçları alır. Bu, silinecek veriyi bulmamıza yardımcı olur.
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] { // Sonuçlar arasında döner ve her bir sonucu NSManagedObject türüne dönüştürür. CoreData'den gelen veriler bu türdendir.
                        if let id = result.value(forKey: "id") as? UUID { // Her sonucun "id" özelliğini kontrol eder ve bu özelliği UUID türüne dönüştürmeye çalışır.
                            if id == idArray[indexPath.row] { // Eğer bu id, silinmek istenen hücrenin id'sine eşitse, silme işlemine başla.
                                context.delete(result) // CoreData'den seçilen veriyi siler.
                                titleArray.remove(at: indexPath.row) // Silinen verinin başlık bilgisini yerel listeden kaldır.
                                idArray.remove(at: indexPath.row) // Silinen verinin kimlik bilgisini yerel listeden kaldır.
                                self.tableView.reloadData() // Tabloyu günceller, böylece silinen veri görünümde de kaldırılır.
                                do {
                                    try context.save() // Yapılan değişiklikleri CoreData'ye kaydeder. Eğer bir hata olursa, ekrana "error" basar.
                                } catch {
                                    print("error")
                                }
                                break // Silme işlemi tamamlandığında döngüden çıkılır.
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
        }
    }
}
