<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ page import="java.sql.*" %>
        <%@ page import="java.time.LocalDate" %>
            <%@ page import="java.time.format.DateTimeParseException" %>
                <%@ page import="java.util.ArrayList" %>
                    <%@ page import="java.util.List" %>
                        <%! public static class OrderRecord { public int id; public String customer; public String
                            garment; public String deliveryDate; public String notes; } private String escapeHtml(String
                            input) { if (input==null) { return "" ; } StringBuilder sb=new StringBuilder(); for (int
                            i=0; i < input.length(); i++) { char c=input.charAt(i); switch (c) { case '&' :
                            sb.append("&amp;"); break; case '<' : sb.append("&lt;"); break; case '>' :
                            sb.append("&gt;"); break; case '"' : sb.append("&quot;"); break; case '\'':
                    sb.append("&#39;");
                    break;
                default:
                    sb.append(c);
            }
        }
        return sb.toString();
    }
%>
<%
    
    String dbUrl = "jdbc:mysql://localhost:3306/tailor_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    String dbUser = "root";
    String dbPassword = System.getenv("TAILOR_DB_PASSWORD");

    String successMessage = null;
    String errorMessage = null;
    List<OrderRecord> orderList = new ArrayList<>();

    request.setCharacterEncoding("UTF-8");
    String customer = request.getParameter("customer");
    String garment = request.getParameter("garment");
    String deliveryDateStr = request.getParameter("delivery_date");
    String notes = request.getParameter("notes");

    LocalDate validDeliveryDate = null;

   
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        if (customer == null || customer.trim().isEmpty()) {
            errorMessage = "Customer name is required.";
        } else if (customer.trim().length() > 40) {
            errorMessage = "Customer name cannot exceed 40 characters.";
        } else if (garment == null || garment.trim().isEmpty()) {
            errorMessage = "Please select a garment.";
        } else if (deliveryDateStr == null || deliveryDateStr.trim().isEmpty()) {
            errorMessage = "Delivery date is required.";
        } else {
            // Server-side date validation
            try {
                validDeliveryDate = LocalDate.parse(deliveryDateStr.trim());
                LocalDate today = LocalDate.now();
                if (validDeliveryDate.isBefore(today)) {
                    errorMessage = "Delivery date cannot be in the past. Please select today or a future date.";
                }
            } catch (DateTimeParseException e) {
                errorMessage = "Invalid delivery date format. Please use YYYY-MM-DD.";
            }
        }
    }

    // Check if the environment variable is configured
    if (dbPassword == null) {
        errorMessage = "Database configuration error: TAILOR_DB_PASSWORD environment variable is not set.";
    } else {
        // Connect to MySQL and perform database operations using try-with-resources
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword)) {

                // If POST request and all server validations passed, insert the record
                if ("POST".equalsIgnoreCase(request.getMethod()) && errorMessage == null && validDeliveryDate != null) {
                    String insertSql = "INSERT INTO tailor_order (customer, garment, delivery_date, notes) VALUES (?, ?, ?, ?)";
                    try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                        insertStmt.setString(1, customer.trim());
                        insertStmt.setString(2, garment.trim());
                        insertStmt.setDate(3, java.sql.Date.valueOf(validDeliveryDate));
                        insertStmt.setString(4, notes != null ? notes.trim() : "");

                        int rows = insertStmt.executeUpdate();
                        if (rows > 0) {
                            successMessage = "Tailor order saved successfully!";
                        }
                    }
                }

                // Retrieve the latest five orders (newest first)
                String selectSql = "SELECT id, customer, garment, delivery_date, notes FROM tailor_order ORDER BY id DESC LIMIT 5";
                try (PreparedStatement selectStmt = conn.prepareStatement(selectSql);
                     ResultSet rs = selectStmt.executeQuery()) {

                    while (rs.next()) {
                        OrderRecord record = new OrderRecord();
                        record.id = rs.getInt("id");
                        record.customer = rs.getString("customer");
                        record.garment = rs.getString("garment");
                        Date d = rs.getDate("delivery_date");
                        record.deliveryDate = (d != null) ? d.toString() : "";
                        record.notes = rs.getString("notes");
                        orderList.add(record);
                    }
                }

            }
        } catch (ClassNotFoundException e) {
            errorMessage = "MySQL JDBC Driver not found. Please ensure the MySQL Connector dependency is included.";
        } catch (SQLException e) {
            errorMessage = "Database Error (" + e.getErrorCode() + "): " + e.getMessage();
        } catch (Exception e) {
            errorMessage = "An unexpected error occurred: " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tailor Order Slip - Order Summary</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="container-wide">
    <h2>Tailor Order Slip - Recent Orders</h2>

    <!-- Success Message -->
    <% if (successMessage != null) { %>
        <div class="alert alert-success">
            <strong>Success:</strong> <%= escapeHtml(successMessage) %>
        </div>
    <% } %>

    <!-- Error Message -->
    <% if (errorMessage != null) { %>
        <div class="alert alert-error">
            <strong>Error:</strong> <%= escapeHtml(errorMessage) %>
        </div>
    <% } %>

    <!-- Latest Orders Table -->
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th style="width: 8%;">ID</th>
                    <th style="width: 25%;">Customer Name</th>
                    <th style="width: 17%;">Garment</th>
                    <th style="width: 18%;">Delivery Date</th>
                    <th style="width: 32%;">Measurements / Notes</th>
                </tr>
            </thead>
            <tbody>
                <% if (orderList.isEmpty()) { %>
                    <tr>
                        <td colspan="5" class="empty-message">No orders found in the database.</td>
                    </tr>
                <% } else { %>
                    <% for (OrderRecord ord : orderList) { %>
                        <tr>
                            <td><%= ord.id %></td>
                            <td><%= escapeHtml(ord.customer) %></td>
                            <td><%= escapeHtml(ord.garment) %></td>
                            <td><%= escapeHtml(ord.deliveryDate) %></td>
                            <td><%= (ord.notes != null && !ord.notes.isEmpty()) ? escapeHtml(ord.notes) : "<em>None</em>" %></td>
                        </tr>
                    <% } %>
                <% } %>
            </tbody>
        </table>
    </div>

    <!-- Link back to index.html -->
    <div class="actions">
        <a href="index.html" class="btn btn-secondary">&larr; Enter Another Order</a>
    </div>
</div>

</body>
</html>