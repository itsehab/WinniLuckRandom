//
//  ImagePicker.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { 
                print("❌ No image provider found")
                return 
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let originalImage = image as? UIImage else {
                            print("❌ Failed to cast image")
                            return
                        }
                        
                        // Validate and optimize the image
                        if let optimizedImage = self?.validateAndOptimizeImage(originalImage) {
                            print("✅ Image validated and optimized successfully")
                            self?.parent.selectedImage = optimizedImage
                        } else {
                            print("❌ Image validation failed")
                        }
                    }
                }
            } else {
                print("❌ Provider cannot load image")
            }
        }
        
        private func validateAndOptimizeImage(_ image: UIImage) -> UIImage? {
            // Check if image is valid
            guard image.size.width > 0 && image.size.height > 0 else {
                print("❌ Invalid image dimensions")
                return nil
            }
            
            // Define maximum dimensions to prevent memory issues
            let maxDimension: CGFloat = 2048
            let maxFileSize: Int = 5_000_000 // 5MB max
            
            // Check file size (approximate)
            if let imageData = image.jpegData(compressionQuality: 0.8),
               imageData.count > maxFileSize {
                print("⚠️ Image too large, will be resized")
            }
            
            // Resize if necessary
            let resizedImage = resizeImageIfNeeded(image, maxDimension: maxDimension)
            
            // Final validation
            guard let finalData = resizedImage.jpegData(compressionQuality: 0.8),
                  finalData.count <= maxFileSize else {
                print("❌ Image still too large after optimization")
                return nil
            }
            
            print("✅ Image validated: \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height)), \(finalData.count) bytes")
            return resizedImage
        }
        
        private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size
            
            // Check if resizing is needed
            if size.width <= maxDimension && size.height <= maxDimension {
                return image
            }
            
            // Calculate new size maintaining aspect ratio
            let aspectRatio = size.width / size.height
            let newSize: CGSize
            
            if size.width > size.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
            
            // Resize the image
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            print("🔄 Image resized from \(Int(size.width))x\(Int(size.height)) to \(Int(newSize.width))x\(Int(newSize.height))")
            return resizedImage
        }
    }
}

// Helper struct for showing image picker
struct ImagePickerButton: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    let title: String
    
    var body: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            HStack {
                Image(systemName: "photo.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
} 