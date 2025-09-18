# DISTRIBUTED-SYSTEMS-AND-APPLICATIONS-ASSIGNMENT-01-2025

DISTRIBUTED SYSTEMS AND APPLICATIONS ASSIGNMENT 01


Course Code: DSA612S

#STUDENT NAMES :

JONAS TOBIAS 21601730, DREDLEEN SO-OABES 223052558, LUKAS M SHINGUDI 223084913, NGOMBE NGARIROKUE 222065435, ABNER KASHIKOLA 200908014

This assignment covers two tasks:

#Question 1: Restful APIs 
The Facilities Directorate at NUST wants to keep track of all the assets it owns, such as laboratory 
equipment, servers, and vehicles. Each asset has important details like its tag, name, faculty, 
department, date acquired, and current status (ACTIVE, UNDER_REPAIR, or DISPOSED). 
But assets are not just single items. Each one can have: 
• Components - parts of the asset, e.g., a motor in a printer or a hard drive in a server. 
• Maintenance schedules - regular servicing plans, e.g., quarterly or yearly checks, with a 
next due date. 
• Work orders - when something breaks, a work order is opened to fix it. 
• Tasks  -  small jobs under a work order, like “replace screen” or “update antivirus.” 
The university wants you to design and implement a RESTful API in Ballerina that will allow 
staff to: 
• Create and manage assets — add new assets, update their information, look them up, or 
remove them. 
• View all assets — get a list of all assets 
• View assets that belong to one faculty 
• Check for overdue items — find assets that have maintenance schedules whose due date 
has already passed. 
• Manage components — add or remove components of an asset. 
• Manage schedules — add or remove servicing schedules for an asset. 
• Manage work orders — open a new work order if an asset is faulty, update its status, or 
close it. 
• Manage tasks — add or remove the small tasks under a work order. 
The main database must be implemented as a map or a table, where each asset is identified by 
its assetTag (the unique key). 
Inside each asset, there are lists of components, schedules, and work orders.  
Your task is to build an API that works like a mini asset-management system for the university. 
It should follow RESTful principles, handle the different entities and their relationships, and 
support operations such as add, update, delete, and search. 
Example of an asset payload 
Create Asset 
{ 
"assetTag": "EQ-001", 
"name": "3D Printer", 
"faculty": "Computing & Informatics", 
"department": "Software Engineering", 
"status": "ACTIVE", 
"acquiredDate": "2024-03-10", 
"components": {}, 
"schedules": {}, 
"workOrders": {} 
} 
Deliverables: 
1. Working Solution (7 marks) 
• Correct setup and compilation. 
• Proper use of the map/table for the main database  
2. Service Implementation (35 marks) 
• Create and manage assets - add, update, look up, or remove assets (10 marks) 
• View all assets - retrieve the full list (3 marks) 
• View assets by faculty- filter by faculty (5 marks) 
• Check for overdue items -return assets with overdue maintenance schedules (5 marks) 
• Manage components- add/remove components for an asset (5 marks) 
• Manage schedules -add/remove schedules for an asset (5 marks) 
(Total = 35 marks) 
3. Client Implementation (10 marks) 
• Ballerina client that correctly interacts with the service. 
• Demonstrates at least: 
o Adding and updating an asset 
o Viewing all assets 
o Viewing by faculty 
o Overdue check 
o Managing at least one component or schedule 
(Total = 10 marks) 



#Question 2: Remote invocation: CAR RENTAL SYSTEM using gRPC 
Your task is to design and implement a gRPC-based CAR RENTAL SYSTEM that supports two 
user roles—Customer and Admin—to manage cars, browse availability, add cars to a rental cart 
(with dates), and place reservations. Customers can view available cars, search for a specific car 
by plate, add it to their cart with intended rental dates, and place a reservation. Admins can add 
new cars, update car details, remove cars, and list all reservations. 
In short, we have the following operations: 
➢ add_car: An admin registers a car in the system (make, model, year, daily price, mileage, 
number plate, status). The system returns the car’s unique ID (the plate).  
➢ create_users () - Multiple users (customers or admins), each with a specific profile, are 
created and streamed to the server. The response is returned once the operation completes. 
➢ update_car () – Admin can change a car’s details using its plate as the key (e.g., adjust the 
daily price, set status to AVAILABLE/UNAVAILABLE). 
➢ remove_car () -Admin can delete a car from the inventory. The server responds with the 
new full list of cars, so the admin sees the updated catalogue. 
➢ list_available_cars () - Customers ask for cars they can rent now. The server streams back 
the available cars one by one (optionally filtered by text like “Toyota” or a year).  
➢ search_car () -Customer looks up a specific car by its plate. If it’s available, the server 
returns its details; otherwise, you’re told it isn’t available. 
➢ add_to_cart () - Customer picks a car (by plate) and supplies start and end dates for the 
rental. The server checks basic rules (dates make sense, car exists). If OK, it adds this 
selection to the customer’s “cart” (a temporary list). 
➢ place_reservation () 
This turns whatever is in the customer’s cart into an actual reservation. The server: 
✓ Verifies that each car is still available for the requested dates (no overlaps). 
✓ Calculates the price (days × daily rate). 
✓ Confirm the booking and clear the cart. 
Your task is to define a protocol buffer contract with the remote functions and implement both the 
client and the server in the Ballerina Language. 
Server Implementation: 
Implement the server logic using the Ballerina Language and gRPC. Your server should handle 
incoming requests from clients and perform appropriate actions based on the requested operation. 
Client Implementation: 
The clients should be able to use the generated gRPC client code to connect to the server and 
perform operations as implemented in the service. Clients should be able to handle user input and 
display relevant information to the user. 
Please be aware that you have the freedom to include additional fields in your records if you 
believe they would enhance the performance and overall quality of your system. 
Deliverables: 
We will follow the criteria below to assess this problem: 
• Definition of the remote interface in Protocol Buffer. (15 marks) 
• Implementation of the gRPC client in the Ballerina language, and able to test the 
application. (10 marks) 
• Implementation of the gRPC server and server-side logic in response to the remote 
invocations in the Ballerina Language. [25 marks]
