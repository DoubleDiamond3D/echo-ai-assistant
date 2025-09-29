//
//  MediaView.swift
//  EchoAI
//
//  Media gallery and wallpaper management
//

import SwiftUI
import Photos
import PhotosUI

struct MediaView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var selectedTab = 0
    @State private var showingImagePicker = false
    @State private var showingVideoPicker = false
    @State private var selectedMedia: MediaItem?
    @State private var showingMediaDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Media Type", selection: $selectedTab) {
                    Text("Photos").tag(0)
                    Text("Videos").tag(1)
                    Text("Wallpapers").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    PhotosView()
                        .tag(0)
                    
                    VideosView()
                        .tag(1)
                    
                    WallpapersView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Take Photo") {
                            showingImagePicker = true
                        }
                        
                        Button("Record Video") {
                            showingVideoPicker = true
                        }
                        
                        Button("Upload from Library") {
                            // Show photo picker
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            CameraView()
        }
        .sheet(isPresented: $showingVideoPicker) {
            CameraView()
        }
        .sheet(isPresented: $showingMediaDetail) {
            if let media = selectedMedia {
                MediaDetailView(media: media)
            }
        }
    }
}

// MARK: - Photos View
struct PhotosView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var selectedPhotos: Set<MediaItem> = []
    @State private var showingDeleteAlert = false
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            // Selection Toolbar
            if !selectedPhotos.isEmpty {
                selectionToolbar
            }
            
            // Photos Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(echoService.photos) { photo in
                        PhotoThumbnail(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo)
                        ) {
                            if selectedPhotos.contains(photo) {
                                selectedPhotos.remove(photo)
                            } else {
                                selectedPhotos.insert(photo)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var selectionToolbar: some View {
        HStack {
            Button("Cancel") {
                selectedPhotos.removeAll()
            }
            
            Spacer()
            
            Text("\(selectedPhotos.count) selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Delete") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let photo: MediaItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                AsyncImage(url: photo.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .background(.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Videos View
struct VideosView: View {
    @EnvironmentObject var echoService: EchoService
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(echoService.videos) { video in
                    VideoThumbnail(video: video)
                }
            }
            .padding()
        }
    }
}

// MARK: - Video Thumbnail
struct VideoThumbnail: View {
    let video: MediaItem
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AsyncImage(url: video.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "video")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
                
                // Play Button
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(video.duration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Wallpapers View
struct WallpapersView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var showingWallpaperPicker = false
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        VStack(spacing: 16) {
            // Current Wallpaper
            currentWallpaperCard
            
            // Wallpaper Gallery
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(echoService.wallpapers) { wallpaper in
                        WallpaperThumbnail(wallpaper: wallpaper)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingWallpaperPicker) {
            WallpaperPickerView()
        }
    }
    
    private var currentWallpaperCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Wallpaper")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Change") {
                    showingWallpaperPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let currentWallpaper = echoService.currentWallpaper {
                AsyncImage(url: currentWallpaper.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("No wallpaper set")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
}

// MARK: - Wallpaper Thumbnail
struct WallpaperThumbnail: View {
    let wallpaper: MediaItem
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: wallpaper.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            
            Text(wallpaper.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .onTapGesture {
            isSelected.toggle()
            // Set as wallpaper
        }
    }
}

// MARK: - Media Detail View
struct MediaDetailView: View {
    let media: MediaItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                AsyncImage(url: media.fullSizeURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .clipped()
                
                Spacer()
            }
            .navigationTitle(media.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        showingShareSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [media.fullSizeURL])
        }
    }
}

// MARK: - Wallpaper Picker View
struct WallpaperPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select a wallpaper")
                    .font(.headline)
                    .padding()
                
                // Photo picker would go here
                Text("Photo picker implementation")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Choose Wallpaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        // Set wallpaper
                        dismiss()
                    }
                    .disabled(selectedImage == nil)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MediaView()
        .environmentObject(EchoService())
}
