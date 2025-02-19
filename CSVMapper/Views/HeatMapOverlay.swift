//
//  HeatMap.swift
//  CSVMapper
//
//  Created by Maximilian Enders on 18.02.25.
//

import SwiftUI
import MapKit

class HeatMapOverlay: NSObject, MKOverlay {
    var personCoordinates: [CLLocationCoordinate2D]
    
    // Berechne den Mittelpunkt der Mitglieder
    var coordinate: CLLocationCoordinate2D {
        guard !personCoordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        let sumLat = personCoordinates.reduce(0.0) { $0 + $1.latitude }
        let sumLon = personCoordinates.reduce(0.0) { $0 + $1.longitude }
        let count = Double(personCoordinates.count)
        return (CLLocationCoordinate2D(latitude: sumLat / count, longitude: sumLon / count))
    }
    
    // Bestimme ein Begrenzungsrechteck, das alle Punkte umschließt
    var boundingMapRect: MKMapRect {
        guard !personCoordinates.isEmpty else {
            return MKMapRect.null
        }
        
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = 0.0
        var maxY = 0.0
        for coord in personCoordinates {
            let point = MKMapPoint(coord)
            if point.x < minX { minX = point.x }
            if point.y < minY { minY = point.y }
            if point.x > maxX { maxX = point.x }
            if point.y > maxY { maxY = point.y }
        }
        return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    init(personCoordinates: [CLLocationCoordinate2D]) {
        self.personCoordinates = personCoordinates
    }
}

// Custom Renderer, der für jeden Personen-Koordinatenpunkt einen radialen Farbverlauf zeichnet
class HeatMapOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let heatOverlay = overlay as? HeatMapOverlay else { return }
        
        // Alpha-Wert für den Fülleffekt
        let alpha: CGFloat = 0.3
        // Radius je nach Zoom-Level anpassen (hier ein Basiswert, der modifiziert werden kann)
        let baseRadius: CGFloat = 100.0
        
        for coord in heatOverlay.personCoordinates {
            let mapPoint = MKMapPoint(coord)
            // Berechne den Punkt im aktuellen Kontext
            let point = self.point(for: mapPoint)
            // Passe den Radius an den aktuellen Zoom-Scale an
            let radius = baseRadius / zoomScale
            let colors = [
                UIColor.red.withAlphaComponent(alpha).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: point, startRadius: 0, endCenter: point, endRadius: radius, options: .drawsAfterEndLocation)
            }
        }
    }
}

// SwiftUI Wrapper für einen MKMapView, der das HeatMapOverlay anzeigt
struct HeatMapMapView: UIViewRepresentable {
    var persons: [Person]
    var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
            let mapView = MKMapView(frame: .zero)
            mapView.delegate = context.coordinator
            mapView.setRegion(region, animated: false)
            return mapView
        }
        
        func updateUIView(_ uiView: MKMapView, context: Context) {
            // Vorherige Overlays entfernen
            uiView.removeOverlays(uiView.overlays)
            
            // Nur valide Koordinaten verwenden
            let coordinates = persons.compactMap { $0.coordinate }
            if !coordinates.isEmpty {
                let overlay = HeatMapOverlay(personCoordinates: coordinates)
                uiView.addOverlay(overlay)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, MKMapViewDelegate {
            var parent: HeatMapMapView
            
            init(_ parent: HeatMapMapView) {
                self.parent = parent
            }
            
            // Übergibt dem MKMapView den passenden Renderer für das HeatMapOverlay
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if overlay is HeatMapOverlay {
                    return HeatMapOverlayRenderer(overlay: overlay)
                }
                return MKOverlayRenderer(overlay: overlay)
            }
        }
    }
