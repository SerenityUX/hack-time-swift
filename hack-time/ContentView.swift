import SwiftUI
import UIKit

struct AsyncImageView: View {
    let url: URL

    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            if let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }
}

struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    var startTime: Date
    var endTime: Date
    let color: Color
}

struct EventView: View {
    let event: CalendarEvent
    let dayStartTime: Date
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(event.title)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                Spacer()
            }
            Spacer()
            
            Text(formatEventTime(start: event.startTime, end: event.endTime))
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14))
        }
        .padding(16) // Increase internal padding
        .frame(width: 320, height: calculateEventHeight())
        .background(event.color)
        .cornerRadius(16)
        .padding(.vertical, 8) // Add 4px padding top and bottom
        .padding(.leading, 16)
    }
    
    private func formatEventTime(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startString = formatter.string(from: start).lowercased()
        let endString = formatter.string(from: end).lowercased()
        return "\(startString) - \(endString)"
    }
    
    private func calculateRelativeTime(_ time: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dayStartTime, to: time)
        return calendar.date(byAdding: components, to: dayStartTime) ?? time
    }
    
    private func calculateEventHeight() -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: event.startTime, to: event.endTime)
        let hours = CGFloat(components.hour ?? 0)
        let minutes = CGFloat(components.minute ?? 0)
        return (hours + minutes / 60) * 72.0 - 16 // Subtract 8px to account for vertical padding
    }
}

struct TimelinePoint: Identifiable {
    let id = UUID()
    let date: Date
    var yPosition: CGFloat = 0
}

struct ContentView: View {
    let startTime: Date
    let endTime: Date
    
    @State private var selectedTag: String = "Event"
    let tags = ["Event", "You", "Dieter", "Nila", "Sam", "Dev", "JC", "Lexi"]
    
    @State private var dragOffset: CGFloat = 0
    @State private var previousDragValue: DragGesture.Value?
    
    // Add this property to store the namespace for the ScrollViewReader
    @Namespace private var tagNamespace
    
    // Add this property to control the visibility of events
    @State private var showEvents: Bool = true
    @State private var eventOffset: CGFloat = 0
    
    // Add this function to generate haptic feedback
    private func generateHapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // Add this state variable in the ContentView struct
    @State private var isAnnouncementModalPresented = false
    
    @State private var timelinePoints: [TimelinePoint] = []
    
    @State private var startTimelinePoint: TimelinePoint?
    @State private var currentTimelinePoint: TimelinePoint?
    
    @State private var events: [CalendarEvent] = []
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    let notificationFeedback = UINotificationFeedbackGenerator()
    
    @State private var isCreatingEvent: Bool = false
    @State private var previewStartTime: Date?
    @State private var previewEndTime: Date?
    
    // Add this property to the ContentView struct
    @State private var lastHourFeedback: Int?
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        
        // Set start time to today at 8:00 AM in the device's local time zone
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 8
        startComponents.minute = 0
        startComponents.second = 0
        self.startTime = calendar.date(from: startComponents)!
        
        // Set end time to 33 hours after start time
        self.endTime = calendar.date(byAdding: .hour, value: 33, to: self.startTime)!
        
        // Add correct events
        let sampleEvents = [
            CalendarEvent(title: "Attendees begin to arrive", 
                          startTime: self.startTime, 
                          endTime: calendar.date(byAdding: .hour, value: 7, to: self.startTime)!, 
                          color: Color(red: 218/255, green: 128/255, blue: 0/255)),
            CalendarEvent(title: "Opening Ceremony", 
                          startTime: calendar.date(byAdding: .hour, value: 7, to: self.startTime)!,
                          endTime: calendar.date(byAdding: .hour, value: 8, to: self.startTime)!,
                          color: Color(red: 2/255, green: 147/255, blue: 212/255)), // 0293D4 in RGB
            CalendarEvent(title: "Dinner + Hacking Begins", 
                          startTime: calendar.date(byAdding: .hour, value: 8, to: self.startTime)!, 
                          endTime: calendar.date(byAdding: .hour, value: 12, to: self.startTime)!, 
                          color: Color(red: 8/255, green: 164/255, blue: 42/255)) // 08A42A in RGB
        ]
        _events = State(initialValue: sampleEvents)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Run Of Show")
                    .font(.largeTitle)
                    .fontWeight(.medium)

                Spacer()

                Button(action: {
                    isAnnouncementModalPresented = true
                }) {
                    Image(systemName: "message.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Color(red: 89/255, green: 99/255, blue: 110/255))
                }
                .padding(.trailing, 8)

                AsyncImageView(url: URL(string: "https://thispersondoesnotexist.com")!)
            }
            .padding()
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .foregroundColor(selectedTag == tag ? .white : Color(red: 89/255, green: 99/255, blue: 110/255))
                                .padding(.horizontal, 12.0)
                                .padding(.vertical, 8.0)
                                .background(selectedTag == tag ? Color.black : Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 89/255, green: 99/255, blue: 110/255), lineWidth: selectedTag == tag ? 0 : 1)
                                )
                                .onTapGesture {
                                    if selectedTag != tag {
                                        selectedTag = tag
                                        generateHapticFeedback()
                                        withAnimation {
                                            proxy.scrollTo(tag, anchor: .center)
                                        }
                                    }
                                }
                                .id(tag)
                        }
                    }
                    .padding([.leading, .bottom, .trailing])
                }
                .onChange(of: selectedTag) { newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            
            
            ScrollView {
                Text("it's hack time you hacker...")
                    .foregroundColor(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0))
                    .frame(height: 8)
                ZStack(alignment: .topLeading) {
                    // Timeline
                    VStack(spacing: 0) {
                        ForEach(timelinePoints) { point in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        if shouldShowWeekday(for: point.date) {
                                            Text(formatWeekday(date: point.date))
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.459))
                                                .frame(width: 32, alignment: .leading)
                                        }
                                        
                                        Text(formatTime(date: point.date))
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.459))
                                            .frame(width: 42, alignment: .leading)
                                    }
                                    .padding(.leading, 12)
                                    .frame(height: 0, alignment: .leading)
                                    
                                    VStack {
                                        Divider()
                                    }
                                }
                                Spacer()
                            }
                            .frame(height: 72.0)
                        }
                    }
                    
                    // Events
                    if showEvents {
                        ForEach(events) { event in
                            EventView(event: event, dayStartTime: startTime)
                                .padding(.leading, 42)
                                .offset(y: calculateEventOffset(for: event))
                                .offset(x: eventOffset)
                                .animation(.spring(), value: eventOffset)
                        }
                        .transition(.move(edge: .leading))
                    }
                    
                    // Event Preview
                    if isCreatingEvent, let start = previewStartTime, let end = previewEndTime {
                        EventPreviewView(startTime: start, endTime: end, dayStartTime: startTime)
                            .padding(.leading, 42)
                            .offset(y: calculateEventOffset(for: CalendarEvent(title: "", startTime: start, endTime: end, color: .clear)))
                    }
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.contentShape(Rectangle())
                            .gesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .sequenced(before: DragGesture(minimumDistance: 0))
                                    .onChanged { value in
                                        switch value {
                                        case .first(true):
                                            break
                                        case .second(true, let drag):
                                            if let location = drag?.location {
                                                if self.startTimelinePoint == nil {
                                                    self.impactHeavy.impactOccurred()
                                                    self.startTimelinePoint = findNearestTimelinePoint(to: location.y)
                                                    self.previewStartTime = self.startTimelinePoint?.date
                                                    self.isCreatingEvent = true
                                                    self.lastHourFeedback = Calendar.current.component(.hour, from: self.previewStartTime ?? Date())
                                                }
                                                self.currentTimelinePoint = findNearestTimelinePoint(to: location.y, roundUp: true)
                                                self.previewEndTime = self.currentTimelinePoint?.date
                                                
                                                // Provide haptic feedback for each hour change (up or down)
                                                if let endTime = self.previewEndTime,
                                                   let lastFeedback = self.lastHourFeedback {
                                                    let currentHour = Calendar.current.component(.hour, from: endTime)
                                                    if currentHour != lastFeedback {
                                                        self.impactMed.impactOccurred(intensity: 0.5)
                                                        self.lastHourFeedback = currentHour
                                                    }
                                                }
                                            }
                                        default:
                                            break
                                        }
                                    }
                                    .onEnded { value in
                                        if let startPoint = self.startTimelinePoint,
                                           let endPoint = self.currentTimelinePoint {
                                            print("Start timeline point: \(formatDate(startPoint.date))\n" +
                                                  "Final timeline point: \(formatDate(endPoint.date))")
                                            createCalendarEvent(start: startPoint.date, end: endPoint.date)
                                        }
                                        self.startTimelinePoint = nil
                                        self.currentTimelinePoint = nil
                                        self.isCreatingEvent = false
                                        self.previewStartTime = nil
                                        self.previewEndTime = nil
                                        self.lastHourFeedback = nil
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture().onChanged { _ in }
                            )
                    }
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let previous = previousDragValue {
                        let delta = value.translation.width - previous.translation.width
                        dragOffset += delta
                        
                        // Update eventOffset for animation
                        if selectedTag == "Event" {
                            eventOffset = dragOffset
                        }
                    }
                    previousDragValue = value
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if dragOffset > threshold {
                        selectPreviousTag()
                    } else if dragOffset < -threshold {
                        selectNextTag()
                    } else {
                        // Reset eventOffset if the drag didn't result in a tag change
                        eventOffset = 0
                    }
                    dragOffset = 0
                    previousDragValue = nil
                }
        )
        .onChange(of: selectedTag) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                showEvents = (newValue == "Event")
                if !showEvents {
                    eventOffset = -UIScreen.main.bounds.width
                } else {
                    eventOffset = 0
                }
            }
        }
        // Add this modifier at the end of the VStack in the body
        .sheet(isPresented: $isAnnouncementModalPresented) {
            AnnouncementModalView(isPresented: $isAnnouncementModalPresented)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            timelinePoints = hoursBetween(start: startTime, end: endTime)
        }
    }

    private func selectNextTag() {
        if let currentIndex = tags.firstIndex(of: selectedTag),
           currentIndex < tags.count - 1 {
            selectedTag = tags[currentIndex + 1]
            generateHapticFeedback()
            animateEventTransition(direction: .trailing)
        }
    }

    private func selectPreviousTag() {
        if let currentIndex = tags.firstIndex(of: selectedTag),
           currentIndex > 0 {
            selectedTag = tags[currentIndex - 1]
            generateHapticFeedback()
            animateEventTransition(direction: .leading)
        }
    }

    private func animateEventTransition(direction: Edge) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedTag == "Event" {
                eventOffset = 0
            } else {
                eventOffset = direction == .leading ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width
            }
        }
    }

    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatWeekday(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func shouldShowWeekday(for date: Date) -> Bool {
        let calendar = Calendar.current
        if date == startTime {
            return true
        }
        let previousHour = calendar.date(byAdding: .hour, value: -1, to: date)!
        return !calendar.isDate(date, inSameDayAs: previousHour)
    }
    
    private func hoursBetween(start: Date, end: Date) -> [TimelinePoint] {
        var points: [TimelinePoint] = []
        var currentDate = start
        var yPosition: CGFloat = 0
        
        while currentDate <= end {
            let point = TimelinePoint(date: currentDate, yPosition: yPosition)
            points.append(point)
            currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
            yPosition += 72.0
        }
        
        return points
    }
    
    private func findNearestTimelinePoint(to yPosition: CGFloat, roundUp: Bool = false) -> TimelinePoint? {
        if roundUp {
            return timelinePoints.first { $0.yPosition >= yPosition }
        } else {
            return timelinePoints.last { $0.yPosition <= yPosition }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter.string(from: date)
    }
    
    private func calculateEventOffset(for event: CalendarEvent) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime, to: event.startTime)
        let hours = CGFloat(components.hour ?? 0)
        let minutes = CGFloat(components.minute ?? 0)
        return (hours + minutes / 60) * 72.0
    }
    
    private func createCalendarEvent(start: Date, end: Date) {
        // Check for overlaps
        if events.contains(where: { event in
            (start >= event.startTime && start < event.endTime) ||
            (end > event.startTime && end <= event.endTime) ||
            (start <= event.startTime && end >= event.endTime)
        }) {
            print("Cannot create event: Overlaps with existing event")
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        // Create new CalendarEvent
        let newEvent = CalendarEvent(
            title: "Unnamed",
            startTime: start,
            endTime: end,
            color: Color(red: 2/255, green: 147/255, blue: 212/255)
        )
        
        // Add to events array
        events.append(newEvent)
        
        print("Event created: \(formatDate(start)) - \(formatDate(end))")
        impactHeavy.impactOccurred()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Modify the AnnouncementModalView structure
struct AnnouncementModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            // Title
            Text("Announcements")
                .font(.system(size: 24))
                .padding()
            
            Divider()
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Announcement content goes here")
                        .foregroundColor(Color(hue: 1.0, saturation: 0.131, brightness: 0.812, opacity: 0.0))
                        .padding(.horizontal)
                    
                    
                    // Add more content as needed
                }
            }
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct EventPreviewView: View {
    let startTime: Date
    let endTime: Date
    let dayStartTime: Date
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Unnamed")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                Spacer()
            }
            Spacer()
            
            Text(formatEventTime(start: startTime, end: endTime))
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14))
        }
        .padding(16)
        .frame(width: 320, height: calculateEventHeight())
        .background(Color(red: 2/255, green: 147/255, blue: 212/255).opacity(0.5))
        .cornerRadius(16)
        .padding(.vertical, 8)
        .padding(.leading, 16)
    }
    
    private func formatEventTime(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startString = formatter.string(from: start).lowercased()
        let endString = formatter.string(from: end).lowercased()
        return "\(startString) - \(endString)"
    }
    
    private func calculateEventHeight() -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime, to: endTime)
        let hours = CGFloat(components.hour ?? 0)
        let minutes = CGFloat(components.minute ?? 0)
        return (hours + minutes / 60) * 72.0 - 16
    }
}

#Preview {
    ContentView()
}

