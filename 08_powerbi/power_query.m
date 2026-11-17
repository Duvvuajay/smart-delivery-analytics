# Power BI – Power Query (M) Script

/*
   This script connects to the MySQL database `smart_delivery_analytics` and imports the
   star‑schema tables defined in `model.md`. It assumes the MySQL ODBC driver is installed
   and configured on the machine (or the native MySQL connector is available in Power BI).
   Adjust the `Server`, `Database`, `Uid`, and `Pwd` values to match your environment.
*/

let
    // ---------------------------------------------------------------------
    // 1. Connection parameters – modify as needed
    // ---------------------------------------------------------------------
    Server = "localhost",   // or IP / hostname of MySQL server
    Database = "smart_delivery_analytics",
    // If you use Windows authentication you can leave Uid/Pwd empty.
    // Otherwise provide a MySQL account with read‑only permissions.
    Uid = "<your_mysql_user>",
    Pwd = "<your_mysql_password>",

    // ---------------------------------------------------------------------
    // 2. Helper function to pull a table or view
    // ---------------------------------------------------------------------
    Source = (ObjectName as text) =>
        let
            ConnectionString =
                "Driver={MySQL ODBC 8.0 Unicode Driver};Server=" & Server & ";Database=" & Database & ";Uid=" & Uid & ";Pwd=" & Pwd & ";",
            Sql = "SELECT * FROM " & ObjectName,
            Result = Odbc.Query(ConnectionString, Sql)
        in
            Result,

    // ---------------------------------------------------------------------
    // 3. Load dimension tables
    // ---------------------------------------------------------------------
    DimCustomer = Source("DimCustomer"),
    DimRestaurant = Source("DimRestaurant"),
    DimPartner = Source("DimPartner"),
    DimDate = Source("DimDate"),

    // ---------------------------------------------------------------------
    // 4. Load fact tables
    // ---------------------------------------------------------------------
    FactOrders =
        let
            Raw = Source("FactOrders"),
            // Convert string dates to actual date types if required (MySQL already returns DATE)
            // Ensure numeric columns are correct type
            Typed = Table.TransformColumnTypes(Raw,{ {"OrderID", Int64.Type}, {"CustomerID", Int64.Type}, {"RestaurantID", Int64.Type}, {"PartnerID", Int64.Type}, {"DateKey", Int64.Type}, {"OrderAmount", type number}, {"DeliveryFee", type number}, {"DeliveryDurationMins", type number}, {"Status", type text} })
        in
            Typed,

    FactPayments =
        let
            Raw = Source("FactPayments"),
            Typed = Table.TransformColumnTypes(Raw,{ {"PaymentID", Int64.Type}, {"OrderID", Int64.Type}, {"DateKey", Int64.Type}, {"Amount", type number}, {"PaymentMode", type text} })
        in
            Typed,

    FactRatings =
        let
            Raw = Source("FactRatings"),
            Typed = Table.TransformColumnTypes(Raw,{ {"RatingID", Int64.Type}, {"OrderID", Int64.Type}, {"DateKey", Int64.Type}, {"CustomerRating", type number}, {"Feedback", type text} })
        in
            Typed,

    // ---------------------------------------------------------------------
    // 5. Optional: Create relationships programmatically (Power BI will infer when
    //    you load to the model, but we expose them here for documentation.)
    // ---------------------------------------------------------------------
    Relationships = {
        // DimDate → Fact tables
        {"DimDate", "DateKey", "FactOrders", "DateKey"},
        {"DimDate", "DateKey", "FactPayments", "DateKey"},
        {"DimDate", "DateKey", "FactRatings", "DateKey"},
        // DimCustomer → FactOrders
        {"DimCustomer", "CustomerID", "FactOrders", "CustomerID"},
        // DimRestaurant → FactOrders
        {"DimRestaurant", "RestaurantID", "FactOrders", "RestaurantID"},
        // DimPartner → FactOrders
        {"DimPartner", "PartnerID", "FactOrders", "PartnerID"},
        // FactOrders → FactPayments / FactRatings (FK on OrderID)
        {"FactOrders", "OrderID", "FactPayments", "OrderID"},
        {"FactOrders", "OrderID", "FactRatings", "OrderID"}
    },

    // ---------------------------------------------------------------------
    // 6. Output – a record containing all loaded tables
    // ---------------------------------------------------------------------
    Output = [
        DimCustomer = DimCustomer,
        DimRestaurant = DimRestaurant,
        DimPartner = DimPartner,
        DimDate = DimDate,
        FactOrders = FactOrders,
        FactPayments = FactPayments,
        FactRatings = FactRatings
    ]
in
    Output
