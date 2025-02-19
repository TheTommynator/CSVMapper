//
//  PersonViewModel.swift
//  CSVMapper
//
//  Created by Maximilian Enders on 17.02.25.
//

import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers
import CSV

class PersonViewModel: ObservableObject {
    @Published var persons: [Person] = []
    
    var expectedTimeLoading: Int {
        return Int(Double(persons.count) * Double(throttlingDelay))
    }
    
    @Published var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Fortschrittsanzeige: 1.0 = alle abgeschlossen
    @Published var geocodingProgress: Double = 0.0
    
    private let geocoder = CLGeocoder()
    
    // Queue für das Throttling der Anfragen, damit die Anzahl der Anfragen nicht > 50 / 60s
    private let throttlingQueue = DispatchQueue(label: "GeocodingQueue", qos: .userInitiated)
    private let throttlingDelay: TimeInterval = 1.3
    
    // Zähler für erfolgreich abgearbeitete (auch fehlerhafte) Geocoding-Anfragen
    private var geocodingCompletedCount = 0
    
    // Importiere Personen von CSV Datei und schreibe sie in das Personen-Array
    func importCSV(from url: URL) {
        
        // Sichere Öffnung der Datei sicherstellen
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            return
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        
        let stream = InputStream(url: url)!
        let csv = try! CSVReader(stream: stream, hasHeaderRow: true)
        
        //print(csv.headerRow!)
        
        var persons: [Person] = []
        
        while csv.next() != nil {
            // Importiere nur vollständige Personendaten
            guard let firstName = csv["Vorname"], let lastName = csv["Name"], let street = csv["Strasse"], let city = csv["Ort"], let postalCode = csv["PLZ"] else { return }
            
            let person = Person(firstName: firstName, lastName: lastName, street: street, postalCode: postalCode, city: city, coordinate: nil)
            persons.append(person)
        }
        
        self.persons = persons
        
        //print(self.persons)
        
        geocodePersons()
        
        //print(self.persons)
        
    }
    
    func geocodePersons() {
        self.geocodingProgress = 0.0
        self.geocodingCompletedCount = 0
        
        for (index, person) in persons.enumerated() {
            throttlingQueue.asyncAfter(deadline: .now() + throttlingDelay * Double(index)) { [weak self] in
                self?.performGeocoding(for: person, at: index)
            }
        }
    }
    
    
    private func performGeocoding(for person: Person, at index: Int) {
        let address = person.fullAddress
        geocoder.geocodeAddressString(address) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard let self = self else { return }
            
            // Unabhängig vom Erfolg als abgeschlossen Zählen
            DispatchQueue.main.async {
                self.geocodingCompletedCount += 1
                withAnimation {
                    self.geocodingProgress = Double(self.geocodingCompletedCount) / Double(self.persons.count)
                }
            }
            
            if let error = error {
                print("Fehler beim Geocoding für die Adresse: \(address): \(error.localizedDescription)")
                return
            }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                DispatchQueue.main.async {
                    self.persons[index].coordinate = coordinate
                    // Optional: Setze das Karten-Zentrum auf die erste gefundene Adresse
                    /*if index == 0   {
                        self.position.center = coordinate
                    }*/
                }
            }
        }
    }
    
}
