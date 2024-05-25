import SwiftUI
import MapKit
import CoreLocation
import CoreMotion
import UIKit


struct ContentView: View {
    @State private var selectedTab = 2 // Главное окно (с трекером)
    @State private var calorieIntake: Double = 1500 // Пример начального приема калорий
    @State private var foodItems: [FoodItem] = [] // Список продуктов питания
    @State private var isAddingFood = false // Состояние для управления добавлением пищи
    @State private var isFoodListVisible = false // Состояние для управления видимостью списка еды
    @StateObject private var pedometerManager = PedometerManager() // Педометр менеджер
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Вкладка профиля пользователя
            NavigationView {
                UserView()
                    .navigationBarTitle("Профиль пользователя")
            }
            .tabItem {
                VStack {
                    Image(systemName: "person")
                    Text("Профиль")
                }
            }
            .tag(0)
            
            // Вкладка карты
            NavigationView {
                MapView()
                    .navigationBarTitle("Карта", displayMode: .large)
            }
            .tabItem {
                VStack {
                    Image(systemName: "map")
                    Text("Карта")
                }
            }
            .tag(1)
            
            // Вкладка кругового трекера калорий
            CircularCalorieTracker(calorieIntake: $calorieIntake, isAddingFood: $isAddingFood, isFoodListVisible: $isFoodListVisible, foodItems: $foodItems, pedometerManager: pedometerManager)
                .tabItem {
                    VStack {
                        Image(systemName: "chart.pie.fill")
                        Text("Прогресс")
                    }
                }
                .tag(2)
            
            // Вкладка программ
            NavigationView {
                ProgramsView()
                    .navigationBarTitle("ПРОГРАММЫ", displayMode: .large)
            }
            .tabItem {
                VStack {
                    Image(systemName: "person.3")
                    Text("Программы")
                }
            }
            .tag(3)
            
            // Вкладка тренировок
            NavigationView {
                TrainingView()
                    .navigationBarTitle("Раздел тренировок")
            }
            .tabItem {
                VStack {
                    Image(systemName: "bolt.circle")
                    Text("Тренировки")
                }
            }
            .tag(4)
        }
        .accentColor(.blue) // Цвет выделенной вкладки
    }
}

class PedometerManager: NSObject, ObservableObject {
    private let pedometer = CMPedometer()
    @Published var stepCount: Int?
    
    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("Подсчет шагов недоступен")
            return
        }
        
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            if let error = error {
                print("Ошибка при запуске обновлений шагомера: \(error)")
            }
            
            guard let self = self, let data = data else { return }
            DispatchQueue.main.async {
                self.stepCount = data.numberOfSteps.intValue
            }
        }
    }
}

struct CircularCalorieTracker: View {
    @Binding var calorieIntake: Double
    @Binding var isAddingFood: Bool // Состояние для управления добавлением пищи
    @Binding var isFoodListVisible: Bool // Состояние для управления видимостью списка еды
    @Binding var foodItems: [FoodItem] // Список продуктов питания
    @ObservedObject var pedometerManager: PedometerManager // Педометр менеджер
    
    @State private var isTrackingSteps = false
    @State private var randomWorkouts: [Workout] = []
    
    var body: some View {
        ScrollView {
            VStack {
                // Верхняя часть с приветствием и иконкой уведомлений
                HStack {
                    VStack(alignment: .leading) {
                        Text("Добро пожаловать, Алексей!")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "bell.fill")
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Квадраты с завершенными упражнениями и трекер калорий
                HStack(spacing: 20) {
                    // Завершенные упражнения
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(1))
                        .frame(width: 160, height: 130)
                        .overlay(
                            VStack {
                                Text("Сделано упражнений")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    
                                Text("2/4")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        )
                    
                    // Круговой трекер калорий
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                                .frame(width: 130, height: 130)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(calorieIntake / 2500))
                                .stroke(Color.blue, lineWidth: 10)
                                .frame(width: 130, height: 130)
                                .rotationEffect(Angle(degrees: -90))
                            
                            Text("\(Int(calorieIntake))/2500")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                withAnimation {
                                    isFoodListVisible.toggle()
                                }
                            }) {
                                Circle()
                                    .foregroundColor(.clear)
                                    .frame(width: 130, height: 130)
                                    .opacity(0.001)
                            }
                        }
                        .sheet(isPresented: $isFoodListVisible) {
                            // Вид списка еды
                            FoodListView(calorieIntake: $calorieIntake, isAddingFood: $isAddingFood, foodItems: $foodItems, isFoodListVisible: $isFoodListVisible)
                        }
                    }
                }
                .padding(.vertical)
                
                // Количество шагов или кнопка для отслеживания
                HStack {
                    if let stepCount = pedometerManager.stepCount {
                        Text("\(stepCount) шагов")
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Button(action: {
                            requestStepTrackingPermission()
                        }) {
                            Text("Следить за шагами")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    Image(systemName: "figure.walk")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Секция с рандомными тренировками
                VStack(alignment: .leading) {
                    Text("Рекомендуемые тренировки")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(randomWorkouts, id: \.id) { workout in
                                WorkoutCard(workout: workout)
                                    .frame(width: 300)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .onAppear {
                loadRandomWorkouts()
            }
        }
    }
    
    func requestStepTrackingPermission() {
        let status = CMPedometer.authorizationStatus()
        if status == .notDetermined {
            pedometerManager.startTracking()
            print("Запрашиваем разрешение и начинаем отслеживание")
        } else if status == .authorized {
            pedometerManager.startTracking()
            print("Уже авторизовано, начинаем отслеживание")
        } else {
            print("Разрешение на использование шагомера отклонено или ограничено")
            // Открываем настройки устройства
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Настройки открыты: \(success)") // Для отладки
                    })
                }
            }
        }
    }
    
    func loadRandomWorkouts() {
        if let url = Bundle.main.url(forResource: "workouts", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let workouts = try decoder.decode([Workout].self, from: data)
                self.randomWorkouts = Array(workouts.shuffled().prefix(3)) // Рандомные 3 тренировки
            } catch {
                print("Ошибка при загрузке данных из файла: \(error)")
            }
        } else {
            print("Невозможно найти файл workouts.json")
        }
    }
}

struct FoodItem: Codable, Identifiable {
    var id = UUID()
    let date: Date // Добавлено свойство для хранения времени съедения продукта
    let name: String
    let calories: Double
    
    init(date: Date = Date(), name: String, calories: Double) {
        self.date = date // Используем текущую дату, если она не указана при создании
        self.name = name
        self.calories = calories
    }
}

class FoodManager {
    static let shared = FoodManager()
    
    private let userDefaults = UserDefaults.standard
    private let keyPrefix = "foodItems_"
    
    func saveFoodItems(forDate date: Date, foodItems: [FoodItem]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(foodItems) {
            userDefaults.set(encoded, forKey: key(forDate: date))
        }
    }
    
    func loadFoodItems(forDate date: Date) -> [FoodItem] {
        if let savedData = userDefaults.data(forKey: key(forDate: date)) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([FoodItem].self, from: savedData) {
                return decoded
            }
        }
        return []
    }
    
    private func key(forDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return "\(keyPrefix)\(dateString)"
    }
}

struct FoodListView: View {
    @Binding var calorieIntake: Double
    @Binding var isAddingFood: Bool
    @Binding var foodItems: [FoodItem] // Список продуктов питания
    @Binding var isFoodListVisible: Bool // Состояние для управления видимостью списка еды
    
    var body: some View {
        NavigationView {
            List {
                // Отображение списка съеденных продуктов здесь
                ForEach(foodItems) { foodItem in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(foodItem.name)
                            Text(formattedTime(date: foodItem.date)) // Передаем дату съедения продукта
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(Int(foodItem.calories)) ккал") // Количество калорий
                    }
                }

                
                // Кнопка для добавления нового продукта питания
                Button(action: {
                    isAddingFood = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Добавить продукт")
                    }
                }
                .foregroundColor(.blue)
            }
            .navigationTitle("Список продуктов")
            .navigationBarItems(trailing: Button(action: {
                isFoodListVisible = false // Закрыть список продуктов питания
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            })
            .sheet(isPresented: $isAddingFood) {
                // Представление для добавления нового продукта питания
                AddFoodView(calorieIntake: $calorieIntake, isAddingFood: $isAddingFood, foodItems: $foodItems)
            }
        }
    }
    
    // Функция для форматирования времени
    func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm" // Формат даты и времени
        return formatter.string(from: date)
    }
}

struct AddFoodView: View {
    @Binding var calorieIntake: Double
    @Binding var isAddingFood: Bool
    @Binding var foodItems: [FoodItem] // Список продуктов питания
    @State private var foodName = ""
    @State private var calories = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Добавить продукт")) {
                    TextField("Наименование продукта", text: $foodName)
                        .autocapitalization(.words) // Автоматическое написание с заглавной буквы
                    TextField("Калории", text: $calories)
                        .keyboardType(.numberPad) // Установка циферной клавиатуры для ввода калорий
                }
                
                Button("Добавить продукт") {
                    if validateInputs() {
                        guard let calories = Double(calories) else { return }
                        let newFoodItem = FoodItem(name: foodName, calories: calories)
                        calorieIntake += calories // Обновить прием калорий
                        foodItems.append(newFoodItem) // Добавляем новый продукт питания в список
                        FoodManager.shared.saveFoodItems(forDate: Date(), foodItems: foodItems) // Сохраняем продукты питания
                        isAddingFood = false
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Ошибка ввода"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .navigationTitle("Добавить продукт")
            .navigationBarItems(trailing: Button("Отмена") {
                isAddingFood = false
            })
        }
    }
    
    // Функция для проверки ввода
    func validateInputs() -> Bool {
        // Проверяем, что название продукта не пустое
        if foodName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Пожалуйста, введите название продукта."
            showAlert = true
            return false
        }
        
        // Проверяем, что калории можно преобразовать в Double и они больше нуля
        if let caloriesValue = Double(calories), caloriesValue > 0 {
            return true
        } else {
            alertMessage = "Пожалуйста, введите допустимое количество калорий."
            showAlert = true
            return false
        }
    }
}

struct TrackerProgramsView: View {
    @State private var workouts: [Workout] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Программы тренировок")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(workouts, id: \.id) { workout in
                        WorkoutCard(workout: workout)
                            .frame(width: 300)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadWorkoutsFromJSON()
        }
    }

    func loadWorkoutsFromJSON() {
        if let url = Bundle.main.url(forResource: "workouts", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                workouts = try decoder.decode([Workout].self, from: data)
            } catch {
                print("Ошибка при загрузке данных из файла: \(error)")
            }
        } else {
            print("Невозможно найти файл workouts.json")
        }
    }
}

struct UserView: View {
    var body: some View {
        Text("Профиль пользователя")
    }
}



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestWhenInUseAuthorization()
        self.manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.first
    }
}

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176), // Координаты Москвы
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var places: [Place] = []

    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: places) { place in
                MapAnnotation(coordinate: place.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                        Text(place.name)
                            .font(.caption)
                            .padding(5)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadPlaces()
            }
            
            VStack(alignment: .leading) {
                Text("Спортивные места")
                    .font(.headline)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(places) { place in
                            VStack(alignment: .leading) {
                                Text(place.name)
                                    .font(.headline)
                                Text(place.category ?? "Неизвестно")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
        }
        .navigationBarTitle("Карта", displayMode: .large)
    }
    
    func loadPlaces() {
        guard let url = Bundle.main.url(forResource: "sports_places_moscow", withExtension: "json") else {
            print("Failed to locate JSON file.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loadedData = try decoder.decode([String: [Place]].self, from: data)
            self.places = loadedData.flatMap { (key, places) in
                places.map { place in
                    Place(name: place.name, coordinate: place.coordinate, category: key)
                }
            }
        } catch {
            print("Failed to load JSON file: \(error)")
        }
    }
}

struct Place: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case coordinates
        case category
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, category: String?) {
        self.name = name
        self.coordinate = coordinate
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        let coordinatesArray = try container.decode([[Double]].self, forKey: .coordinates)
        let coordinate = CLLocationCoordinate2D(latitude: coordinatesArray[0][0], longitude: coordinatesArray[0][1])
        self.coordinate = coordinate
    }
}

extension CLLocationCoordinate2D: Decodable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(CLLocationDegrees.self)
        let longitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}


struct ProgramsView: View {
    @State private var workouts: [Workout] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedWorkouts.keys.sorted(), id: \.self) { muscleGroup in
                        Section(header: Text("\(muscleGroup)".uppercased()).font(.title).padding(.top)) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(groupedWorkouts[muscleGroup] ?? [], id: \.id) { workout in
                                        NavigationLink(destination: WorkoutDetailView(workout: workout)
                                            .navigationBarTitle(workout.name, displayMode: .inline)) { // Просмотреть другой способ!!!
                                            WorkoutCard(workout: workout)
                                                .frame(width: 300) // Ширина карточки
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding()
            }
            
            .onAppear {
                loadWorkoutsFromJSON()
            }
            
        }
    }

    func loadWorkoutsFromJSON() {
        if let url = Bundle.main.url(forResource: "workouts", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                print("Данные успешно загружены из файла workouts.json")
                let decoder = JSONDecoder()
                workouts = try decoder.decode([Workout].self, from: data)
            } catch {
                print("Ошибка при загрузке данных из файла: \(error)")
            }
        } else {
            print("Невозможно найти файл workouts.json")
        }
    }

    var groupedWorkouts: [String: [Workout]] {
        Dictionary(grouping: workouts, by: { $0.muscleGroup })
    }
}


struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if workout.isFavorite {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                        .font(.headline)
                } else {
                    Image(systemName: "bookmark")
                        .foregroundColor(.gray)
                        .font(.headline)
                }
            }
            
            // Место для изображения
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 150)
                .padding(.vertical, 8) // Примерный отступ между текстом и изображением
                
            HStack {
                difficultyIndicator(for: workout.difficulty)
                Spacer()
                Text("\(workout.estimatedDuration) мин")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(workout.estimatedCaloriesBurned) ккал") // Новое поле калорий
                                    .font(.headline)
                                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    func difficultyIndicator(for difficulty: String) -> some View {
        var filledLightningCount: Int
        var emptyLightningCount: Int
        switch difficulty {
        case "Легко":
            filledLightningCount = 1
            emptyLightningCount = 2
        case "Средне":
            filledLightningCount = 2
            emptyLightningCount = 1
        case "Сложно":
            filledLightningCount = 3
            emptyLightningCount = 0
        default:
            filledLightningCount = 0
            emptyLightningCount = 3
        }
        
        return HStack(spacing: 2) {
            ForEach(0..<filledLightningCount, id: \.self) { _ in
                Image(systemName: "bolt.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            ForEach(0..<emptyLightningCount, id: \.self) { _ in
                Image(systemName: "bolt")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
    }
}


struct WorkoutDetailView: View {
    let workout: Workout
    @State private var isDescriptionExpanded = false
    private let maxDescriptionLength = 80 // Максимальная длина предварительного просмотра
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(workout.name)
                    .font(.largeTitle)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 90, height: 45)
                                .foregroundColor(Color.secondary.opacity(0.3))
                                .overlay(
                                    Text("\(workout.estimatedDuration) мин")
                                        .foregroundColor(.primary)
                                        .bold()
                                        .font(.title3)
                                )
                        }
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 80, height: 45)
                                .foregroundColor(Color.secondary.opacity(0.3))
                                .overlay(
                                    difficultyIndicator(for: workout.difficulty)
                                )
                        }
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 90, height: 45)
                                .foregroundColor(Color.secondary.opacity(0.3))
                                .overlay(
                                    Text("\(workout.workoutsPerWeek) \(pluralForm(for: workout.workoutsPerWeek))")
                                        .foregroundColor(.primary)
                                        .bold()
                                        .font(.title3)
                                )
                        }
                        VStack { // Отображения калорий
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 110, height: 45)
                                .foregroundColor(Color.secondary.opacity(0.3))
                                .overlay(
                                    Text("\(workout.estimatedCaloriesBurned) ккал")
                                        .foregroundColor(.primary)
                                        .bold()
                                        .font(.title3)
                                )
                        }
                    }
                }
                
                Text("Описание:")
                    .font(.headline)
                    .foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDescriptionExpanded ? workout.description : getDescriptionPreview())
                    
                    if !isDescriptionExpanded && workout.description.count > maxDescriptionLength {
                        Button("Подробнее") {
                            isDescriptionExpanded.toggle()
                        }
                        .foregroundColor(.blue)
                        .font(.callout)
                    }
                }
                
                if workout.author != "" {
                    Text("Автор: \(workout.author)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if workout.muscleGroup != "" {
                    Text("Группа мышц: \(workout.muscleGroup)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                ForEach(workout.exercises, id: \.name) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                        Text("Повторов в подходе: \(exercise.repsPerSet)")
                        Text("Подходов: \(exercise.sets)")
                        Text("Время отдыха между подходами: \(exercise.restTimeBetweenSets) сек")
                        Text("Техника выполнения:")
                        Text(exercise.techniqueDescription)
                            .padding(.horizontal)
                        Image(exercise.techniqueImageName)
                            .resizable()
                            .scaledToFit()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
            .padding()
        }
        .navigationBarTitle(workout.name)
    }
    
    func difficultyIndicator(for difficulty: String) -> some View {
        var filledLightningCount: Int
        var emptyLightningCount: Int
        switch difficulty {
        case "Легко":
            filledLightningCount = 1
            emptyLightningCount = 2
        case "Средне":
            filledLightningCount = 2
            emptyLightningCount = 1
        case "Сложно":
            filledLightningCount = 3
            emptyLightningCount = 0
        default:
            filledLightningCount = 0
            emptyLightningCount = 3
        }
        
        return HStack(spacing: 2) {
            ForEach(0..<filledLightningCount, id: \.self) { _ in
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color.red)
                    .font(.title3)
            }
            ForEach(0..<emptyLightningCount, id: \.self) { _ in
                Image(systemName: "bolt")
                    .foregroundColor(Color.gray)
                    .font(.title3)
            }
        }
    }
    
    func getDescriptionPreview() -> String {
        if workout.description.count <= maxDescriptionLength {
            return workout.description
        } else {
            let substring = workout.description.prefix(maxDescriptionLength)
            if let lastSpace = substring.lastIndex(of: " ") {
                let lastIndex = workout.description.index(lastSpace, offsetBy: 1)
                return String(workout.description[..<lastIndex])
            } else {
                return String(substring)
            }
        }
    }
    
    func pluralForm(for number: Int) -> String {
        if number % 10 == 1 && number != 11 {
            return "раз"
        } else if number % 10 >= 2 && number % 10 <= 4 && (number < 12 || number > 14) {
            return "раза"
        } else {
            return "раз"
        }
    }
}
struct Workout: Codable, Identifiable {
    struct Exercise: Codable {
        let name: String
        let repsPerSet: Int
        let sets: Int
        let restTimeBetweenSets: Int
        let techniqueDescription: String
        let techniqueImageName: String
    }
    
    let id: Int
    let isFavorite: Bool
    let name: String
    let author: String
    let muscleGroup: String
    let mainImageName: String
    let workoutsPerWeek: Int
    let exercises: [Exercise]
    let description: String
    let difficulty: String
    let estimatedDuration: Int
    let estimatedCaloriesBurned: Int // Новое поле для калорий
}




struct TrainingView: View {
    var body: some View {
        Text("Раздел тренировок")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
