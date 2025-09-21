import ballerina/http;
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
type MAINTENANCE_SCHEDULE record{
    string id?;
    string maintenance_frequency;
    time:Utc due_date;
};

type COMPONENTS record{
    string name;
    string description;
};
type TASK record{
    string? id;
    string description;
};
type WORKORDER record{
    string id?;
    time:Utc opendate?;
    status current_status = PENDING;
    TASK[] TASK = [];
    time:Utc closedate?;
};


type ASSET record{
    readonly string assetTag;
    string name;
    string faculty;
    string department;
    time:Utc date_aquired;
    status current_status;
    COMPONENTS?[] components= [];
    MAINTENANCE_SCHEDULE?[] maintenance_schedules = [];
    WORKORDER?[] work_orders = [];
};

final table <ASSET> key(assetTag) assets_table = table [{
    assetTag: "EQ-001",
    name: "Laptop",
    faculty: "Engineering",
    department: "Computer Science",
    date_aquired: time:utcNow(),
    current_status: ACTIVE
}];

service / on new http:Listener(9090) {

    resource function post assets(ASSET req) returns string|error {
        if (assets_table.hasKey(req.assetTag)) {
            return error("Asset with assetTag " + req.assetTag + " already exists.");
        }
        else {
            assets_table.add(req);
            return "Asset has been added to the database";
        }
    }

    resource function post assets/[string assetTag]/components(COMPONENTS component) returns string|error{
        if (assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            asset.components.push(component);
            return "Component has been added to asset with assetTag " + assetTag;
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    resource function post assets/[string assetTag]/schedules(MAINTENANCE_SCHEDULE schedule) returns string|error{
        if (assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            asset.maintenance_schedules.push(schedule);
            return "Maintenance schedule has been added to asset with assetTag " + assetTag;
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    resource function post assets/[string assetTag]/workorders(WORKORDER work_order) returns string|error{
        if (assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            work_order.id = uuid:createType1AsString();
            work_order.opendate = time:utcNow();
            asset.work_orders.push(work_order);
            return "Work order has been added to asset with assetTag " + assetTag;
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
        
    }

    resource function post assets/[string assetTag]/workorders/[string workorderId]/tasks(TASK task) returns string|error {  
        if(assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            foreach var [i, workorder] in asset.work_orders.enumerate() {
                if workorder is WORKORDER && workorder.id == workorderId {
                    task.id = uuid:createType1AsString();
                    workorder.TASK.push(task);
                    asset.work_orders[i] = workorder;
                    return "Task has been added to work order " + workorderId + " of asset with assetTag " + assetTag;
                }
            }
            return error("Work order " + workorderId + " not found for asset with assetTag " + assetTag);
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    
    resource function delete assets/[string assetTag]() returns string|error {
        if (assets_table.hasKey(assetTag)) {
            ASSET result = assets_table.remove(assetTag);
            return "Asset with assetTag " + result.assetTag + " has been deleted.";
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    resource function delete assets/[string assetTag]/components/[string componentName]() returns string|error {
        if (assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            asset.components = from var item in asset.components
                               where item?.name != componentName
                               select item;
            return "Component " + componentName + " has been deleted from asset with assetTag " + assetTag;
        }
        else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }      
    }

    resource function delete assets/[string assetTag]/schedules/[string scheduleId]() returns string|error {
        if (assets_table.hasKey(assetTag)) {
            ASSET asset = assets_table.get(assetTag);
            asset.maintenance_schedules = from var item in asset.maintenance_schedules
                                          where item?.id != scheduleId
                                          select item;
            return "Maintenance schedule with id " + scheduleId + " has been deleted from asset with assetTag " + assetTag;
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    resource function delete assets/[string assetTag]/workorders/[string workorderId]() returns string|error {
        if assets_table.hasKey(assetTag) {
            ASSET asset = assets_table.get(assetTag);
            asset.work_orders = from var item in asset.work_orders
                               where item?.id != workorderId
                               select item;
            return "Work order with id " + workorderId + " has been deleted from asset with assetTag " + assetTag;
        }   
        else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }

    }

    resource function get assets() returns ASSET[]|error{
        if (assets_table.length() == 0) {
            return error("No ASSET found in the database.");
        } else {
            return assets_table.toArray();
        }
    }

    resource function get assets/[string assetTag]() returns ASSET|error {
        if (assets_table.hasKey(assetTag)) {
            return assets_table.get(assetTag);
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }

    resource function get assets/faculty/[string faculty]() returns ASSET[]|error {
        ASSET[] facultyAssets = [];
        if (assets_table.length() == 0) {
            return error("No ASSET found in the database.");
        }
        facultyAssets = from var asset in assets_table
                        where asset.faculty == faculty
                        select asset;
        return facultyAssets;               
    }

    
    resource function get assets/overdue() returns ASSET[] {
        ASSET[] overdueAssets = [];
        time:Utc currentDate = time:utcNow();
        foreach ASSET asset in assets_table {
            MAINTENANCE_SCHEDULE?[] schedules = asset.maintenance_schedules;
            foreach MAINTENANCE_SCHEDULE? schedule in schedules {
                if schedule?.due_date < currentDate {
                    overdueAssets.push(asset);
                    break;
                }            
            }
        }
        return overdueAssets;
    }

    resource function put assets/[string assetTag](ASSET updatedAsset) returns string|error {
        if (assets_table.hasKey(assetTag)) {
            assets_table.put(updatedAsset);
            return "Asset with assetTag " + assetTag + " has been updated.";
        } else {
            return error("Asset with assetTag " + assetTag + " not found.");
        }
    }
}   