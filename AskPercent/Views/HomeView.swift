import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CalculatorViewModel()
    @FocusState private var isInputFocused: Bool

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    private var pageBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(uiColor: .secondarySystemGroupedBackground)
        : Color(uiColor: .systemBackground)
    }

    private var cardBorder: Color {
        Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.55 : 0.35)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                inputField
                chips

                if let message = viewModel.parseFailureMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                if let current = viewModel.current {
                    ResultCardView(result: current.result, settings: store.settings)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))

                    if viewModel.isAmbiguous, !viewModel.alternatives.isEmpty {
                        ambiguitySection
                    }
                } else {
                    emptyState
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle(strings.appTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.current != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleFavoriteCurrent()
                    } label: {
                        Image(systemName: viewModel.isCurrentFavorite ? "star.fill" : "star")
                    }
                    .accessibilityLabel(viewModel.isCurrentFavorite ? strings.removeFavoriteAccessibility : strings.addFavoriteAccessibility)
                }
            }
        }
        .onAppear {
            viewModel.bind(store: store)
            requestInputFocus()
        }
        .onChange(of: navigation.selectedTab) { _, newValue in
            if newValue == 0 {
                requestInputFocus()
            } else {
                isInputFocused = false
            }
        }
        .onChange(of: navigation.pendingQuery) { _, newValue in
            guard let newValue else { return }
            viewModel.applyQuery(newValue)
            requestInputFocus()
            navigation.pendingQuery = nil
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.current?.id)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(strings.headerTitle)
                .font(.title3.weight(.semibold))
            Text(strings.headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputField: some View {
        VStack(spacing: 8) {
            TextField(strings.queryPlaceholder, text: $viewModel.query, axis: .vertical)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )

            if viewModel.isAmbiguous {
                Text(strings.ambiguityHint)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(strings.examplePrompts, id: \.self) { prompt in
                    PromptChipView(text: prompt) {
                        viewModel.applyQuery(prompt)
                        isInputFocused = false
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var ambiguitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.alternativesTitle)
                .font(.headline)

            ForEach(viewModel.alternatives) { candidate in
                AlternativeCandidateRow(candidate: candidate, settings: store.settings) {
                    viewModel.chooseCandidate(candidate)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.emptyStateTitle)
                .font(.headline)
            Text(strings.emptyStateBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private func requestInputFocus() {
        DispatchQueue.main.async {
            isInputFocused = true
        }
    }
}
