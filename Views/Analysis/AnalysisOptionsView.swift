import SwiftUI

struct AnalysisOptionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isShowing: Bool
    @State private var showDocumentPicker = false
    @State private var selectedType: HomeViewModel.FileType?
    
    var body: some View {
        VStack(spacing: 8) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.top, 6)
            
            // Options
            ForEach(HomeViewModel.FileType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                    viewModel.selectedFileType = type
                    showDocumentPicker = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(type.description)
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8)
        )
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 30 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowing = false
                        }
                    }
                }
        )
        .sheet(isPresented: $showDocumentPicker) {
            if let type = selectedType {
                DocumentPicker(
                    types: type.allowedTypes,
                    onSelection: { url in
                        viewModel.analyzeFile(url: url, type: type)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowing = false
                        }
                    }
                )
            }
        }
    }
}

// Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 