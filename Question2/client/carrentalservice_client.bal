import ballerina/io;

CarRentalServiceClient ep = check new ("http://localhost:9090");

public function main() returns error? {
    io:println("==========================================");
    io:println("🚗 Welcome to the Car Rental System! 🚗");
    io:println("==========================================");
    boolean shouldContinue = true;
    while (shouldContinue) {
        string|error choiceInput = io:readln("==========================================\n🚗 CAR RENTAL SYSTEM 🚗\n==========================================\n\n👨‍💼 ADMIN OPERATIONS:\n1. ➕ Add Car\n2. ✏️  Update Car\n3. 🗑️  Remove Car\n8. 👥 Create Users\n9. 📋 List All Reservations\n\n👤 CUSTOMER OPERATIONS:\n4. 🚙 List Available Cars\n5. 🔍 Search Car\n6. 🛒 Add to Cart\n7. 💳 Place Reservation\n\n10. 🚪 Exit\n\n==========================================\nEnter your choice: ");
        if choiceInput is error {
            io:println("\n❌ ERROR: Invalid input. Please try again.");
            continue;
        }
        
        int|error choice = int:fromString(choiceInput);
        if choice is error {
            io:println("\n❌ ERROR: Please enter a valid number.");
            continue;
        }
        
        if choice == 1 {
            Car|error car = inputCarDetails();
            if car is error {
                io:println("\n❌ ERROR: ", car.message());
                continue;
            }
            CarResponse|error response = ep->AddCar(car);
            if response is error {
                io:println("\n❌ ERROR: Failed to connect to server. Please ensure the service is running.");
            } else if response.success {
                io:println("\n✅ SUCCESS: ", response.message);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 2 {
            CarUpdateRequest updateRequest = check inputCarUpdateRequest();
            CarResponse response = check ep->UpdateCar(updateRequest);
            if response.success {
                io:println("\n✅ SUCCESS: ", response.message);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 3 {
            RemoveCarRequest removeRequest = check inputRemoveCarRequest();
            CarList response = check ep->RemoveCar(removeRequest);
            io:println("\n✅ CAR REMOVED SUCCESSFULLY!");
            io:println("🚗 Remaining Cars: ", response.cars.length());
            foreach Car car in response.cars {
                io:println("  🚙 ", car.plate_number, " (", car.make, " ", car.model, ")");
            }
        } else if choice == 4 {
            FilterRequest filterRequest = check inputFilterRequest();
            stream<Car, error?> carsStream = check ep->ListAvailableCars(filterRequest);
            io:println("\n🚙 AVAILABLE CARS");
            io:println("==========================================");
            check carsStream.forEach(function(Car car) {
                io:println("🚗 Plate: ", car.plate_number);
                io:println("📝 Make: ", car.make, " ", car.model, " (", car.year, ")");
                io:println("💰 Price: $", car.daily_price, "/day");
                io:println("🛣️  Mileage: ", car.mileage, " miles");
                io:println("📊 Status: ", car.status);
                io:println("------------------------------------------");
            });
        } else if choice == 5 {
            SearchRequest searchRequest = check inputSearchRequest();
            CarResponse response = check ep->SearchCar(searchRequest);
            if response.success {
                io:println("\n✅ CAR FOUND!");
                io:println("🚗 ", response.message);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 6 {
            CartItem cartItem = check inputCartItem();
            CartResponse response = check ep->AddToCart(cartItem);
            if response.success {
                io:println("\n✅ SUCCESS: ", response.message);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 7 {
            ReservationRequest reservationRequest = check inputReservationRequest();
            ReservationResponse response = check ep->PlaceReservation(reservationRequest);
            if response.success {
                io:println("\n✅ RESERVATION PLACED SUCCESSFULLY!");
                io:println("💳 ", response.message);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 8 {
            UserCreationResponse response = check createUsers();
            if response.success {
                io:println("\n✅ SUCCESS: ", response.message);
                io:println("👥 Users Created: ", response.users_created);
            } else {
                io:println("\n❌ ERROR: ", response.message);
            }
        } else if choice == 9 {
            Empty request = {};
            stream<Reservation, error?> reservationsStream = check ep->ListAllReservations(request);
            io:println("\n📋 ALL RESERVATIONS");
            io:println("==========================================");
            check reservationsStream.forEach(function(Reservation reservation) {
                io:println("🆔 ID: ", reservation.reservation_id);
                io:println("👤 User: ", reservation.user_id);
                io:println("💰 Total: $", reservation.total_price);
                io:println("📊 Status: ", reservation.status);
                io:println("📅 Created: ", reservation.created_at);
                io:println("🚗 Cars:");
                foreach CartItem item in reservation.items {
                    io:println("    🚙 Car: ", item.plate_number, " | 📅 Dates: ", item.start_date, " to ", item.end_date);
                }
                io:println("------------------------------------------");
            });
        } else if choice == 10 {
            shouldContinue = false;
            io:println("\n==========================================");
            io:println("👋 Thank you for using the Car Rental System! Goodbye! 👋");
            io:println("==========================================");
        } else {
            io:println("\n❌ Invalid choice. Please try again.");
        }
        
        if (shouldContinue) {
            string|error input = io:readln("Press Enter to continue...");
            if input is error {
                // Ignore read error and continue
            }
        }
    }
}


function inputCarDetails() returns Car|error {
    io:println("\n🚗 ADD NEW CAR");
    io:println("==========================================");
    
    string|error plateInput = io:readln("🏷️  Enter plate number: ");
    if plateInput is error {
        return error("Failed to read plate number");
    }
    
    string|error makeInput = io:readln("🏭 Enter make (e.g., Toyota): ");
    if makeInput is error {
        return error("Failed to read make");
    }
    
    string|error modelInput = io:readln("🚙 Enter model (e.g., Camry): ");
    if modelInput is error {
        return error("Failed to read model");
    }
    
    string|error yearInput = io:readln("📅 Enter year: ");
    if yearInput is error {
        return error("Failed to read year");
    }
    
    string|error priceInput = io:readln("💰 Enter daily price: ");
    if priceInput is error {
        return error("Failed to read daily price");
    }
    
    string|error mileageInput = io:readln("🛣️  Enter mileage: ");
    if mileageInput is error {
        return error("Failed to read mileage");
    }
    
    string|error statusInput = io:readln("📊 Enter status (AVAILABLE/MAINTENANCE/UNAVAILABLE): ");
    if statusInput is error {
        return error("Failed to read status");
    }
    
    //TypeCasting with error handling
    int|error year = int:fromString(yearInput);
    if year is error {
        return error("Invalid year format");
    }
    
    float|error daily_price = float:fromString(priceInput);
    if daily_price is error {
        return error("Invalid price format");
    }
    
    float|error mileage = float:fromString(mileageInput);
    if mileage is error {
        return error("Invalid mileage format");
    }
    
    string normalizedStatus = statusInput.toUpperAscii().trim();
    
    // Validate status input
    if normalizedStatus != "AVAILABLE" && normalizedStatus != "MAINTENANCE" && 
       normalizedStatus != "UNAVAILABLE" && normalizedStatus != "RENTED" {
        return error("Invalid status. Please enter: AVAILABLE, MAINTENANCE, UNAVAILABLE, or RENTED");
    }
    
    CarStatus status = <CarStatus>normalizedStatus;
    
    return {
        plate_number: plateInput, 
        make: makeInput, 
        model: modelInput, 
        year: year, 
        daily_price: daily_price, 
        mileage: mileage, 
        status: status
    };
}
function inputCarUpdateRequest() returns CarUpdateRequest|error {
    CarUpdateRequest request = {};
    request.plate_number = io:readln("Enter plate number of car to update: ");
    
    string daily_price_input = io:readln("Enter new daily price (or press enter to skip): ");
    if (daily_price_input != "") {
        float daily_price = check float:fromString(daily_price_input);
        request.daily_price = daily_price;
    }
    
    string mileage_input = io:readln("Enter new mileage (or press enter to skip): ");
    if (mileage_input != "") {
        float mileage = check float:fromString(mileage_input);
        request.mileage = mileage;
    }
    
    string status_input = io:readln("Enter new status (AVAILABLE/MAINTENANCE/UNAVAILABLE) or press enter to skip: ");
    if (status_input != "") {
        request.status = <CarStatus>status_input.toUpperAscii();
    }
    
    return request;
}

function inputRemoveCarRequest() returns RemoveCarRequest|error {
    RemoveCarRequest request = {};
    request.plate_number = io:readln("Enter plate number of car to remove: ");
    return request;
}

function inputSearchRequest() returns SearchRequest|error {
    SearchRequest request = {};
    request.plate_number = io:readln("Enter plate number to search: ");
    return request;
}

function inputFilterRequest() returns FilterRequest|error {
    FilterRequest request = {};
    
    string make_input = io:readln("Enter make filter (or press enter to skip): ");
    if (make_input != "") {
        request.make = make_input;
    }
    
    string model_input = io:readln("Enter model filter (or press enter to skip): ");
    if (model_input != "") {
        request.model = model_input;
    }
    
    string year_input = io:readln("Enter year filter (or press enter to skip): ");
    if (year_input != "") {
        int year = check int:fromString(year_input);
        request.year = year;
    }
    
    return request;
}

function inputCartItem() returns CartItem|error {
    CartItem item = {};
    item.user_id = io:readln("Enter user ID: ");
    item.plate_number = io:readln("Enter plate number: ");
    item.start_date = io:readln("Enter start date (YYYY-MM-DD): ");
    item.end_date = io:readln("Enter end date (YYYY-MM-DD): ");
    return item;
}

function inputReservationRequest() returns ReservationRequest|error {
    ReservationRequest request = {};
    request.user_id = io:readln("Enter user ID: ");
    return request;
}

function createUsers() returns UserCreationResponse|error {
    CreateUsersStreamingClient streamingClient = check ep->CreateUsers();
    
    while true {
        User user = {};
        string user_id = io:readln("Enter user ID (or 'done' to finish): ");
        if (user_id == "done") {
            break;
        }
        
        user.user_id = user_id;
        user.name = io:readln("Enter name: ");
        user.email = io:readln("Enter email: ");
        string role_input = io:readln("Enter role (CUSTOMER/ADMIN): ");
        string normalizedRole = role_input.toUpperAscii().trim();
        
        // Validate role input
        if normalizedRole != "CUSTOMER" && normalizedRole != "ADMIN" {
            io:println("❌ ERROR: Invalid role. Please enter: CUSTOMER or ADMIN");
            continue;
        }
        
        user.role = <UserRole>normalizedRole;
        
        check streamingClient->sendUser(user);
    }
    
    check streamingClient->complete();
    UserCreationResponse? response = check streamingClient->receiveUserCreationResponse();
    return response is UserCreationResponse ? response : {success: false, message: "No response received", users_created: 0};
}