import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerina/uuid;

enum status {
    ACTIVE,
    UNDER_REPAIR,
    DISPOSED,
    PENDING
};

enum maintenance_frequency {
    MONTHLY,
    QUARTERLY,
    YEARLY
};
type maintenance_schedule record{
    string id?;
    string maintenance_frequency;
    time:Utc due_date;
};

type COMPONENTS record{
    string? id ;
    string name;
    string description;
};
type TASK record{
    string? id;
    string description;
};
type WORKORDER record{
    string? id;
    time:Utc opendate?;
    status current_status = PENDING;
    TASK[] TASK = [];
    time:Utc closedate?;
};

type ASSET record{
    string assetTag;
    string name;
    string faculty;
    string department;
    time:Utc date_aquired = time:utcNow();
    status current_status;
    COMPONENTS?[] components= [];
    maintenance_schedule?[] maintenance_schedules = [];
    WORKORDER?[] work_orders = [];
};

http:Client endPoint = check new ("http://localhost:9090");
public function main() {
    io:println("==========================================");
    io:println("🎉 Welcome to the Asset Management System! 🎉");
    io:println("==========================================");
    boolean shouldContinue = true;
    while (shouldContinue) {
        string|error choiceInput = io:readln("==========================================\n🔧 ASSET MANAGEMENT SYSTEM 🔧\n==========================================\n\n📝 ASSET OPERATIONS:\n1. ➕ Add New Asset\n2. 📋 View All Assets\n3. 🔍 View Single Asset\n4. ✏️  Update Asset\n5. 🗑️  Delete Asset\n\n🔧 COMPONENT OPERATIONS:\n6. ➕ Add Component to Asset\n7. 🗑️  Delete Component from Asset\n\n📅 MAINTENANCE OPERATIONS:\n8. ➕ Add Maintenance Schedule\n9. 🗑️  Delete Maintenance Schedule\n10. 📋 Check Overdue Maintenance Items\n\n🛠️  WORK ORDER OPERATIONS:\n11. ➕ Add Work Order to Asset\n12. 🗑️  Delete Work Order from Asset\n13. ➕ Add Task to Work Order\n\n📊 REPORTING:\n14. 🏛️  View Assets by Faculty\n\n15. 🚪 Exit\n\n==========================================\nEnter your choice: ");
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
            ASSET|error asset = inputData();
            if asset is error {
                io:println("\n❌ ERROR: Failed to input asset data. Please try again.");
                continue;
            }
            var res = addNewAsset(asset);
            if res is string {
                io:println("\n✅ SUCCESS: ", res);
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 2 {
            var res = getAllAssets();
            if res is ASSET[] {
                io:println("\n📋 ALL ASSETS REPORT");
                io:println("==========================================");
                io:println("📊 Total Assets: ", res.length());
                io:println("==========================================");
                foreach ASSET asset in res {
                    io:println("🏷️  Tag: ", asset.assetTag);
                    io:println("📝 Name: ", asset.name);
                    io:println("🏛️  Faculty: ", asset.faculty);
                    io:println("🏢 Department: ", asset.department);
                    io:println("📊 Status: ", asset.current_status);
                    io:println("------------------------------------------");
                }
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 3 {
            string assetTag = io:readln("🔍 Enter Asset Tag: ");
            var res = getAsset(assetTag);
            if res is ASSET {
                io:println("\n🔍 ASSET DETAILS");
                io:println("==========================================");
                io:println("🏷️  Tag: ", res.assetTag);
                io:println("📝 Name: ", res.name);
                io:println("🏛️  Faculty: ", res.faculty);
                io:println("🏢 Department: ", res.department);
                io:println("📊 Status: ", res.current_status);
                io:println("🔧 Components: ", res.components.length());
                io:println("📅 Maintenance Schedules: ", res.maintenance_schedules.length());
                io:println("🛠️  Work Orders: ", res.work_orders.length());
                io:println("==========================================");
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 4 {
            string|error assetTagInput = io:readln("✏️  Enter Asset Tag to update: ");
            if assetTagInput is error {
                io:println("\n❌ ERROR: Failed to read asset tag");
                continue;
            }
            ASSET|error asset = inputData();
            if asset is error {
                io:println("\n❌ ERROR: ", asset.message());
                continue;
            }
            asset.assetTag = assetTagInput;
            var res = updateAsset(asset);
            if res is string {
                io:println("\n✅ SUCCESS: ", res);
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 5 {
            string|error assetTagInput = io:readln("🗑️  Enter Asset Tag to delete: ");
            if assetTagInput is error {
                io:println("\n❌ ERROR: Failed to read asset tag");
                continue;
            }
            var res = deleteAsset(assetTagInput);
            if res is string {
                io:println("\n✅ SUCCESS: ", res);
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 6 {
            io:println("\n🔧 ADD COMPONENT");
            io:println("==========================================");
            string assetTag = io:readln("🏷️  Enter Asset Tag: ");
            string name = io:readln("📝 Enter Component Name: ");
            string description = io:readln("📄 Enter Component Description: ");
            COMPONENTS component = {id: uuid:createType1AsString(), name: name, description: description};
            var res = addComponent(assetTag, component);
            if res is string {
                io:println("\n✅ SUCCESS: ", res);
            } else {
                io:println("\n❌ ERROR: ", res.message());
            }
        } else if choice == 7 {
            string assetTag = io:readln("Enter Asset Tag: ");
            string componentName = io:readln("Enter Component Name to delete: ");
            var res = deleteComponent(assetTag, componentName);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 8 {
            string assetTag = io:readln("Enter Asset Tag: ");
            string freqStr = io:readln("Enter Maintenance Frequency (MONTHLY, QUARTERLY, YEARLY): ");
            string normalizedFreq = freqStr.toUpperAscii().trim();
            
            // Validate frequency input
            if normalizedFreq != "MONTHLY" && normalizedFreq != "QUARTERLY" && normalizedFreq != "YEARLY" {
                io:println("❌ ERROR: Invalid frequency. Please enter: MONTHLY, QUARTERLY, or YEARLY");
                continue;
            }
            
            maintenance_frequency freq = <maintenance_frequency>normalizedFreq;
        string dueDateStr = io:readln("Enter Due Date (YYYY-MM-DDTHH:MM:SSZ): ");
        time:Utc due_date = checkpanic time:utcFromString(dueDateStr);
            maintenance_schedule schedule = {maintenance_frequency: normalizedFreq, due_date: due_date};
            var res = addMaintenanceSchedule(assetTag, schedule);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 9 {
            string assetTag = io:readln("Enter Asset Tag: ");
            string scheduleId = io:readln("Enter Schedule ID to delete: ");
            var res = deleteMaintenance(assetTag, scheduleId);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 10 {
            string assetTag = io:readln("Enter Asset Tag: ");
            WORKORDER workorder = {id: uuid:createType1AsString(), opendate: time:utcNow()};
            var res = addWorkOrder(assetTag, workorder);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 11 {
            string assetTag = io:readln("Enter Asset Tag: ");
            string workorderId = io:readln("Enter Work Order ID to delete: ");
            var res = deleteWorkOrder(assetTag, workorderId);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 12 {
            string assetTag = io:readln("Enter Asset Tag: ");
            string workorderId = io:readln("Enter Work Order ID: ");
            string description = io:readln("Enter Task Description: ");
            TASK task = {id: uuid:createType1AsString(), description: description};
            var res = addTask(assetTag, workorderId, task);
            if res is string {
                io:println(res);
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 13 {
            string faculty = io:readln("Enter Faculty name: ");
            var res = getAssetsByFaculty(faculty);
            if res is ASSET[] {
                io:println("Assets in Faculty '", faculty, "': ", res.length());
                foreach ASSET asset in res {
                    io:println("Asset Tag: ", asset.assetTag, " | Name: ", asset.name, " | Department: ", asset.department, " | Status: ", asset.current_status);
                }
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 14 {
            var res = checkOverdueItems();
            if res is ASSET[] {
                io:println("Overdue Assets: ", res.length());
                foreach ASSET asset in res {
                    io:println("Asset Tag: ", asset.assetTag, " | Name: ", asset.name, " | Faculty: ", asset.faculty, " | Department: ", asset.department);
                }
            } else {
                io:println("Error: ", res.message());
            }
        } else if choice == 15 {
            shouldContinue = false;
            io:println("\n==========================================");
            io:println("👋 Thank you for using the Asset Management System! Goodbye! 👋");
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

function inputData() returns ASSET|error {
    io:println("\n📝 ADD NEW ASSET");
    io:println("==========================================");
    
    string|error assetTagInput = io:readln("🏷️  Enter Asset Tag: ");
    if assetTagInput is error {
        return error("Failed to read asset tag");
    }
    
    string|error nameInput = io:readln("📝 Enter Asset Name: ");
    if nameInput is error {
        return error("Failed to read asset name");
    }
    
    string|error facultyInput = io:readln("🏛️  Enter Faculty: ");
    if facultyInput is error {
        return error("Failed to read faculty");
    }
    
    string|error departmentInput = io:readln("🏢 Enter Department: ");
    if departmentInput is error {
        return error("Failed to read department");
    }
    
    string|error statusInput = io:readln("📊 Enter Status (ACTIVE, UNDER_REPAIR, DISPOSED, PENDING): ");
    if statusInput is error {
        return error("Failed to read status");
    }
    
    string normalizedStatus = statusInput.toUpperAscii().trim();
    
    // Validate status input
    if normalizedStatus != "ACTIVE" && normalizedStatus != "UNDER_REPAIR" && 
       normalizedStatus != "DISPOSED" && normalizedStatus != "PENDING" {
        return error("Invalid status. Please enter: ACTIVE, UNDER_REPAIR, DISPOSED, or PENDING");
    }
    
    status current_status = <status>normalizedStatus;

    return {
        assetTag: assetTagInput,
        name: nameInput,
        faculty: facultyInput,
        department: departmentInput,
        current_status: current_status
    };
}

function addNewAsset(ASSET asset) returns string|error {
    string|error res = endPoint->post("/assets", asset);
    return res;
}

function getAllAssets() returns ASSET[]|error {
    ASSET[]|error res = endPoint->get("/assets");
    return res;
}

function getAsset(string assetTag) returns ASSET|error {
    ASSET|error res = endPoint->get("/assets/" + assetTag);
    return res;
}

function updateAsset(ASSET asset) returns string|error {
    string|error res = endPoint->put("/assets/" + asset.assetTag, asset);
    return res;
}

function addComponent(string assetTag, COMPONENTS component) returns string|error {
    string|error res = endPoint->post("/assets/" + assetTag + "/components", component);
    return res;
}

function addMaintenanceSchedule(string assetTag, maintenance_schedule schedule) returns string|error {
    string|error res = endPoint->post("/assets/" + assetTag + "/schedules", schedule);
    return res;
}

function addWorkOrder(string assetTag, WORKORDER workorder) returns string|error {
    string|error res = endPoint->post("/assets/" + assetTag + "/workorders", workorder);
    return res;
}

function addTask(string assetTag, string workorderId, TASK task) returns string|error {
    string|error res = endPoint->post("/assets/" + assetTag + "/workorders/" + workorderId + "/tasks", task);
    return res;
}

function deleteAsset(string assetTag) returns string|error {
    string|error res = endPoint->delete("/assets/" + assetTag);
    return res;
}

function deleteComponent(string assetTag, string componentName) returns string|error {
    string|error res = endPoint->delete("/assets/" + assetTag + "/components/" + componentName);
    return res;
}

function deleteMaintenance(string assetTag, string scheduleId) returns string|error {
    string|error res = endPoint->delete("/assets/" + assetTag + "/schedules/" + scheduleId);
    return res;
}

function deleteWorkOrder(string assetTag, string workorderId) returns string|error {
    string|error res = endPoint->delete("/assets/" + assetTag + "/workorders/" + workorderId);
    return res;
}

function getAssetsByFaculty(string faculty) returns ASSET[]|error {
    ASSET[]|error res = endPoint->get("/assets/faculty/" + faculty);
    return res;
}

function checkOverdueItems() returns ASSET[]|error {
    ASSET[]|error res = endPoint->get("/assets/overdue");
    return res;
}


