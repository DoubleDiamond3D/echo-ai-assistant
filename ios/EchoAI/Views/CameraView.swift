//
//  CameraView.swift
//  EchoAI
//
//  Live camera feed and photo/video capture
//

import SwiftUI
import AVFoundation
import Photos

struct CameraView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var isRecording = false
    @State private var showingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreviewView()
                    .ignoresSafeArea()
                
                // Overlay UI
                VStack {
                    // Top Controls
                    topControls
                    
                    Spacer()
                    
                    // Bottom Controls
                    bottomControls
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Dismiss camera view
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPhotoLibrary = true }) {
                        Image(systemName: "photo.on.rectangle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        HStack {
            // Flash Control
            Button(action: toggleFlash) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Camera Switch
            Button(action: switchCamera) {
                Image(systemName: "camera.rotate.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Recording Indicator
            if isRecording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                    
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            HStack(spacing: 40) {
                // Photo Library
                Button(action: { showingPhotoLibrary = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                // Capture Button
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                    }
                }
                
                // Video/Photo Toggle
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "video.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        echoService.capturePhoto { image in
            capturedImage = image
            showingImagePicker = true
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            echoService.stopRecording()
        } else {
            echoService.startRecording()
        }
        isRecording.toggle()
    }
    
    private func toggleFlash() {
        echoService.toggleFlash()
    }
    
    private func switchCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        echoService.switchCamera(to: cameraPosition)
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Add camera preview layer
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview if needed
    }
}

// MARK: - Photo Library View
struct PhotoLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Photo Library")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Placeholder for photo grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
                        ForEach(0..<20) { index in
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(EchoService())
}
