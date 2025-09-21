import ballerina/grpc;
import ballerina/time;
import ballerina/uuid;

listener grpc:Listener ep = new (9090);

table<Car> key(plate_number) cars_table = table[];
table<CartItem> key(user_id) cart_table = table[];
table<User> key(user_id) users_table = table[];
table<Reservation> key(reservation_id) reservations_table = table[];



@grpc:Descriptor {value: CAR_RENTAL_DESC}
service "CarRentalService" on ep {

    remote function AddCar(Car value) returns CarResponse|error {
        if (cars_table.hasKey(value.plate_number)) {
            return {success: false, message: "Car with ID " + value.plate_number + " already exists."};
        }
        else {
            cars_table.add(value);
            return {success: true, message: "Car with ID " + value.plate_number + " added successfully.", car: value};
        }
    }

    remote function UpdateCar(CarUpdateRequest value) returns CarResponse|error {
        if (cars_table.hasKey(value.plate_number)){
            Car car = cars_table.get(value.plate_number);
            // Update fields if provided
            if (value.daily_price is float) {
                car.daily_price = value.daily_price;
            }
            if (value.status is CarStatus) {
                car.status = value.status;
            }
            if (value.mileage is float) {
                car.mileage = value.mileage;
            }
            cars_table.put(car);
            return {success: true, message: "Car with ID " + value.plate_number + " updated successfully.", car: car};
        }
        else {
            return {success: false, message: "Car with ID " + value.plate_number + " does not exist."};
        }
    }

    remote function RemoveCar(RemoveCarRequest value) returns CarList|error {
        if (cars_table.hasKey(value.plate_number)){
            Car car = cars_table.remove(value.plate_number);
            return {cars: cars_table.toArray()};
        }
        else {
            return error("Car with ID " + value.plate_number + " does not exist.");
        }
    }

    remote function SearchCar(SearchRequest value) returns CarResponse|error {
        if (cars_table.hasKey(value.plate_number)){
            Car car = cars_table.get(value.plate_number);
            return {success: true, message: "Car found: " + car.make + " " + car.model + " (" + car.year.toString() + ")" + 
                    ", Available: " + car.status.toString() + ", Daily Price: $" + car.daily_price.toString() + ", Mileage: " + car.mileage.toString(), car: car};
        }
        else {
            return {success: false, message: "Car with ID " + value.plate_number + " does not exist."};
        }
    }

    remote function AddToCart(CartItem value) returns CartResponse|error {
        if (!users_table.hasKey(value.user_id)){
            return error("User with ID " + value.user_id + " does not exist.");
        }
        else if (!cars_table.hasKey(value.plate_number)){
            return error("Car with ID " + value.plate_number + " does not exist.");
        }
        else {
            // Check if car is available
            Car car = cars_table.get(value.plate_number);
            if (car.status != AVAILABLE) {
                return error("Car with ID " + value.plate_number + " is not available for rental.");
            }
            
            // Add or update cart item
            cart_table.put(value);
            CartItem[] userItems = from var item in cart_table.toArray()
                                  where item.user_id == value.user_id
                                  select item;
            return {success: true, message: "Car with ID " + value.plate_number + " added to cart for user " + value.user_id + ".", items: userItems};
        }
    }


    remote function PlaceReservation(ReservationRequest value) returns ReservationResponse|error {
        if (!users_table.hasKey(value.user_id)){
            return error("User with ID " + value.user_id + " does not exist.");
        }
        
        // Get user's cart items
        CartItem[] userCartItems = from var item in cart_table.toArray()
                                  where item.user_id == value.user_id
                                  select item;
        
        if (userCartItems.length() == 0) {
            return error("Cart is empty for user " + value.user_id + ".");
        }
        
        // Validate all cars are still available and calculate total price
        float total_price = 0.0;
        foreach CartItem cartItem in userCartItems {
            if (!cars_table.hasKey(cartItem.plate_number)) {
                return error("Car " + cartItem.plate_number + " no longer exists.");
            }
            
            Car car = cars_table.get(cartItem.plate_number);
            if (car.status != AVAILABLE) {
                return error("Car " + cartItem.plate_number + " is no longer available.");
            }
            
            // Calculate days and price
            time:Utc startDate = check time:parse(cartItem.start_date);
            time:Utc endDate = check time:parse(cartItem.end_date);
            int days = check time:utcDiffInSeconds(endDate, startDate) / (24 * 60 * 60);
            total_price += days * car.daily_price;
        }
        
        // Create reservation
        Reservation reservation = {
            reservation_id: uuid:createType1AsString(),
            user_id: value.user_id,
            items: userCartItems,
            total_price: total_price,
            status: CONFIRMED,
            created_at: time:utcToString(time:utcNow())
        };
        
        // Update car statuses to RENTED
        foreach CartItem cartItem in userCartItems {
            Car car = cars_table.get(cartItem.plate_number);
            car.status = RENTED;
            cars_table.put(car);
        }
        
        // Remove items from cart
        foreach CartItem cartItem in userCartItems {
            cart_table.remove(cartItem);
        }
        
        // Store reservation
        reservations_table.put(reservation);
        
        return {success: true, message: "Reservation placed successfully. Total price: $" + total_price.toString(), reservation: reservation};
    }

    remote function CreateUsers(stream<User, grpc:Error?> clientStream) returns UserCreationResponse|error {
        User[] users = [];
        check clientStream.forEach(function (User user) {
            users_table.add(user);
            users.push(user);
        });
        return {success: true, message: "Users created successfully.", users_created: users.length()};
    }

    remote function ListAvailableCars(FilterRequest value) returns stream<Car, error?>|error {
        var availableCars = stream from Car car in cars_table
                              where car.status == AVAILABLE
                              && (value.make is () || car.make == value.make)
                              && (value.model is () || car.model == value.model)
                              && (value.year is () || car.year == value.year)
                              select car;
        
        return availableCars;
    }

    remote function ListAllReservations(Empty value) returns stream<Reservation, error?>|error {
        stream<Reservation, error?> allReservations = stream from Reservation res in reservations_table
                                                        select res;
        return allReservations;
    }
}
