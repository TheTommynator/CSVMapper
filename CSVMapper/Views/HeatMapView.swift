//
//  HeatMapView.swift
//  CSVMapper
//
//  Created by Maximilian Enders on 17.02.25.
//

import SwiftUI
import MapKit
import UniformTypeIdentifiers

struct HeatMapView: View {
    
    @EnvironmentObject var viewModel: PersonViewModel
    
    @State private var error: Error?
    @State private var isImporting = false
    
    @State private var showNameLabels: Bool = true
    
    
    var body: some View {
        NavigationStack {
            VStack {
                HeatMapMapView(persons: viewModel.persons, region: viewModel.region)
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .navigationTitle("CSV Mapper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isImporting = true
                    } label: {
                        //Label("Open CSV", systemImage: "square.and.arrow.down")
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Öffne CSV")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.geocodingProgress < 1.0 && viewModel.geocodingProgress > 0.0 {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.geocodingProgress) {
                                
                            } currentValueLabel: {
                                HStack {
                                    Text("Koordinaten suchen ihren Platz: \(Int(viewModel.geocodingProgress * 100))%")
                                    Spacer()
                                    Text("Erwartete Zeit: \((viewModel.expectedTimeLoading % 3600) / 60):\((viewModel.expectedTimeLoading % 3600) % 60)")
                                }
                            }
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: UIScreen.main.bounds.width / 3.3)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.geocodingProgress)
                        }
                    }
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [UTType.commaSeparatedText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let url):
                    viewModel.importCSV(from: url.first!)
                case .failure(let error):
                    print("Fehler beim Importieren: \(error)")
                }
            }
        }
    }
}

#Preview {
    HeatMapView()
}
