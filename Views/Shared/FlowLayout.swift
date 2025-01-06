import SwiftUI

struct FlowLayout: Layout {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    
    init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = generateRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + spacing * CGFloat(rows.count - 1)
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = generateRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            switch alignment {
            case .leading:
                x = bounds.minX
            case .center:
                x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing:
                x = bounds.maxX - row.width
            default:
                break
            }
            
            for item in row.items {
                let itemSize = item.sizeThatFits(proposal)
                item.place(at: CGPoint(x: x, y: y), proposal: proposal)
                x += itemSize.width + spacing
            }
            
            y += row.height + spacing
        }
    }
    
    private func generateRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var itemsInCurrentRow = 0
        let maxItemsPerRow = 3 // Sabit olarak 3 öğe
        
        for subview in subviews {
            let itemSize = subview.sizeThatFits(proposal)
            
            if itemsInCurrentRow == maxItemsPerRow || 
               (currentRow.width + itemSize.width + spacing > (proposal.width ?? 0) && !currentRow.items.isEmpty) {
                rows.append(currentRow)
                currentRow = Row()
                itemsInCurrentRow = 0
            }
            
            currentRow.items.append(subview)
            currentRow.width += itemSize.width + (currentRow.items.count > 1 ? spacing : 0)
            currentRow.height = max(currentRow.height, itemSize.height)
            itemsInCurrentRow += 1
        }
        
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var items: [LayoutSubview] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
} 