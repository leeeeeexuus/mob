//
//  ContentView.swift
//  Mob
//
//  Created by Aleksey Nizikov on 02.03.2024.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 2 // Главное окно (с трекером)
    @State private var calorieIntake: Double = 1500 // Пример начального приема калорий
    @State private var foodItems: [FoodItem] = [] // Список продуктов питания
    @State private var isAddingFood = false // Состояние для управления добавлением пищи
    @State private var isFoodListVisible = false // Состояние для управления видимостью списка еды
    
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
                    .navigationBarTitle("Карта")
            }
            .tabItem {
                VStack {
                    Image(systemName: "map")
                    Text("Карта")
                }
            }
            .tag(1)
            
            // Вкладка кругового трекера калорий
            CircularCalorieTracker(calorieIntake: $calorieIntake, isAddingFood: $isAddingFood, isFoodListVisible: $isFoodListVisible, foodItems: $foodItems)
                .tabItem {
                    VStack {
                        Image(systemName: "chart.pie.fill")
                        Text("Трекер")
                    }
                }
                .tag(2)
            
            // Вкладка программ
            NavigationView {
                ProgramsView()
                    .navigationBarTitle("Раздел программ")
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
    }
}

struct CircularCalorieTracker: View {
    @Binding var calorieIntake: Double
    @Binding var isAddingFood: Bool // Состояние для управления добавлением пищи
    @Binding var isFoodListVisible: Bool // Состояние для управления видимостью списка еды
    @Binding var foodItems: [FoodItem] // Список продуктов питания
    
    var body: some View {
        // Реализация кругового трекера калорий
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 10)
                .frame(width: 200, height: 200)
                .onTapGesture {
                    withAnimation {
                        isFoodListVisible.toggle() // Переключение видимости списка еды по касанию
                    }
                }
            
            Circle()
                .trim(from: 0.0, to: CGFloat(calorieIntake / 2500)) // ИЗМЕНИТЬ для пользователя
                .stroke(Color.blue, lineWidth: 10)
                .frame(width: 200, height: 200)
                .rotationEffect(Angle(degrees: -90))
                .onTapGesture {
                    withAnimation {
                        isFoodListVisible.toggle() // Переключение видимости списка еды по касанию
                    }
                }
            
            Text("\(calorieIntake, specifier: "%.0f")/2500")
                .font(.title)
                .fontWeight(.bold)
            
            // Добавляем круг в качестве кнопки
            Button(action: {
                withAnimation {
                    isFoodListVisible.toggle() // Переключение видимости списка еды
                }
            }) {
                Circle()
                    .foregroundColor(.clear)
                    .frame(width: 200, height: 200)
                    .opacity(0.001) // Скрываем круг, чтобы он был невидимым, но активным для нажатия
            }
        }
        .sheet(isPresented: $isFoodListVisible) {
            // Вид списка еды
            FoodListView(calorieIntake: $calorieIntake, isAddingFood: $isAddingFood, foodItems: $foodItems, isFoodListVisible: $isFoodListVisible)
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Добавить продукт")) {
                    TextField("Наименование продукта", text: $foodName)
                    TextField("Калории", text: $calories)
                        .keyboardType(.numberPad)
                }
                
                Button("Добавить продукт") {
                    guard let calories = Double(calories) else { return }
                    let newFoodItem = FoodItem(name: foodName, calories: calories)
                    calorieIntake += calories // Обновить прием калорий
                    foodItems.append(newFoodItem) // Добавляем новый продукт питания в список
                    FoodManager.shared.saveFoodItems(forDate: Date(), foodItems: foodItems) // Сохраняем продукты питания
                    isAddingFood = false
                }
            }
            .navigationTitle("Добавить продукт")
            .navigationBarItems(trailing: Button("Отмена") {
                isAddingFood = false
            })
        }
    }
}

struct UserView: View {
    var body: some View {
        Text("Профиль пользователя")
    }
}

struct MapView: View {
    var body: some View {
        Text("Карта")
    }
}

struct ProgramsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CategoryView(categoryName: "Спина", programs: [
                        Program(name: "Программа для силового развития спины", image: "back_workout", category: "Спина", trainingProgram: TrainingProgram(daysPerWeek: 3, exercises: [Exercise(name: "Подтягивания", description: "Описание упражнения", sets: 3, reps: 10)])),
                        Program(name: "Программа для гипертрофии спины", image: "back_hypertrophy", category: "Спина", trainingProgram: TrainingProgram(daysPerWeek: 5, exercises: [Exercise(name: "Подтягивания", description: "Описание упражнения", sets: 4, reps: 8)])),
                        Program(name: "Программа для выносливости спины", image: "back_endurance", category: "Спина", trainingProgram: TrainingProgram(daysPerWeek: 3, exercises: [Exercise(name: "Бег", description: "Описание упражнения", sets: 1, reps: 30)]))
                    ])
                    
                    CategoryView(categoryName: "Бицепс", programs: [
                        Program(name: "Программа для силового развития бицепса", image: "biceps_workout", category: "Бицепс", trainingProgram: TrainingProgram(daysPerWeek: 4, exercises: [Exercise(name: "Подъемы штанги", description: "Описание упражнения", sets: 5, reps: 8)])),
                        Program(name: "Программа для гипертрофии бицепса", image: "biceps_hypertrophy", category: "Бицепс", trainingProgram: TrainingProgram(daysPerWeek: 3, exercises: [Exercise(name: "Молотки", description: "Описание упражнения", sets: 4, reps: 10)])),
                        Program(name: "Программа для выносливости бицепса", image: "biceps_endurance", category: "Бицепс", trainingProgram: TrainingProgram(daysPerWeek: 2, exercises: [Exercise(name: "Обратные подъемы", description: "Описание упражнения", sets: 3, reps: 15)]))
                    ])
                }
                .padding()
            }
            .navigationBarTitle("Программы")
        }
    }
}


struct CategoryView: View {
    var categoryName: String
    var programs: [Program]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(categoryName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(programs) { program in
                        NavigationLink(destination: ProgramDetailView(program: program)) {
                            ProgramCard(program: program)
                        }
                    }
                }
            }
        }
    }
}

struct ProgramCard: View {
    var program: Program
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(program.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .clipped()
                .cornerRadius(10)
            
            Text(program.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }
}

struct Program: Identifiable { // Добавлено соответствие протоколу Identifiable
    var id = UUID() // Создание уникального идентификатора
    var name: String
    var image: String
    var category: String
    var trainingProgram: TrainingProgram // Добавляем программу тренировок
}


struct TrainingProgram {
    var daysPerWeek: Int
    var exercises: [Exercise]
}

struct Exercise: Hashable {
    var id = UUID() // Добавляем идентификатор для уникальности
    
    var name: String
    var description: String
    var sets: Int
    var reps: Int
}


struct ProgramDetailView: View {
    var program: Program
    
    var body: some View {
        VStack {
            Text(program.name)
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Категория: \(program.category)")
                .font(.headline)
                .padding(.bottom)
            
            Text("Тренировочная программа:")
                .font(.headline)
                .padding(.bottom)
            
            ForEach(program.trainingProgram.exercises, id: \.self) { exercise in
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.subheadline)
                    Text("Описание: \(exercise.description)")
                        .font(.caption)
                    Text("Подходы: \(exercise.sets), Повторения: \(exercise.reps)")
                        .font(.caption)
                        .padding(.bottom)
                }
            }
        }
        .navigationBarTitle(program.name)
    }
}


struct ProgramsView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramsView()
    }
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
