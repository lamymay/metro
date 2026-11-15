import SwiftUI

public struct SearchBar: View {
  @Binding var text: String
  @Binding var isMultiSelect: Bool
  // 获取焦点状态，用于控制键盘
  @FocusState private var isSearchFieldFocused: Bool
  @EnvironmentObject private var theme: ThemeManager

  public init(text: Binding<String>, isMultiSelect: Binding<Bool>) {
    self._text = text
    self._isMultiSelect = isMultiSelect
  }

  public var body: some View {
    HStack {
      HStack {
        Image(systemName: "magnifyingglass").foregroundColor(.gray)
        TextField("", text: $text)
          .focused($isSearchFieldFocused)
          // 用户点击键盘上的“/完成”时收起键盘
          .onSubmit { isSearchFieldFocused = false }
      }
      .padding(8)
      .background(Color.systemGray6)
      .cornerRadius(10)

      Button(action: {
        // 切换多选模式
        withAnimation { isMultiSelect.toggle() }
        // 切换模式时自动收起键盘
        isSearchFieldFocused = false
      }) {
        Image(systemName: isMultiSelect ? "checkmark.circle.fill" : "circle.grid.2x2")
          .foregroundColor(isMultiSelect ? theme.primary : .gray)
          .font(.title3)
      }
    }
    .padding()
  }
}
