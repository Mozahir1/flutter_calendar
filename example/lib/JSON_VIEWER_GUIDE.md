# JSON Storage Viewer - User Guide

## 🎯 What You Can Do Now

I've created a complete JSON storage viewer system that lets you:

1. **View JSON Documents** - See all your events stored in JSON format
2. **Add Mock Events** - Generate sample data to test the system
3. **Export Data** - Copy all JSON data to clipboard
4. **Real-time Updates** - See changes immediately as you add/edit events

## 🚀 How to Access

### From the Main App:

1. Open the Flutter Calendar app
2. On the home page, you'll see two new buttons:
   - **"Enhanced Event System"** - Test the new event management
   - **"JSON Storage Viewer"** - View the JSON documents

### From Enhanced Event System:

1. Go to "Enhanced Event System"
2. Click the **code icon** (</>) in the app bar
3. This opens the JSON viewer directly

## 📱 JSON Viewer Features

### **Storage Statistics**

- See total events, recurring events, single events, and collections
- Real-time counts that update as you add/remove events

### **Events Display**

- **Expandable List**: Click the arrow to expand/collapse individual events
- **Formatted JSON**: Pretty-printed JSON with proper indentation
- **Selectable Text**: Copy individual event data by selecting text
- **Event Summary**: Shows event title or ID in the collapsed view

### **Mock Data Generation**

- **"Add Mock Events" Button**: Creates sample events including:
  - Team Meeting (recurring weekly)
  - Doctor Appointment (single event)
  - Project Deadline (single event)
- **Realistic Data**: Events with proper dates, times, and recurrence settings

### **Export Functionality**

- **Copy All Data**: Exports complete JSON including events, collections, and stats
- **Clipboard Integration**: Data is copied to your device's clipboard
- **Formatted Output**: Clean, readable JSON structure

## 🔍 What You'll See in the JSON

### **Event Structure**

```json
{
  "id": "1234567890123",
  "title": "Team Meeting",
  "description": "Weekly team sync",
  "date": "2024-03-15T00:00:00.000Z",
  "endDate": "2024-03-15T00:00:00.000Z",
  "startTime": "2024-03-15T10:00:00.000Z",
  "endTime": "2024-03-15T11:00:00.000Z",
  "colorHex": "ff2196f3",
  "parentEventId": null,
  "recurrenceSettings": {
    "frequency": 2,
    "weekdays": [1, 3, 5],
    "endDate": "2024-12-31T00:00:00.000Z",
    "occurrences": null,
    "recurrenceEndOn": 1
  },
  "createdAt": "2024-03-15T09:00:00.000Z",
  "updatedAt": "2024-03-15T09:00:00.000Z"
}
```

### **Key Fields Explained**

- **`id`**: Unique identifier for each event
- **`parentEventId`**: Links modified occurrences to original recurring events
- **`recurrenceSettings`**: Defines how often the event repeats
- **`colorHex`**: Event color in hexadecimal format
- **`createdAt/updatedAt`**: Timestamps for tracking changes

## 🧪 Testing the System

### **Step 1: Add Mock Events**

1. Go to JSON Storage Viewer
2. Click "Add Mock Events" button
3. You'll see 3 new events appear in the list

### **Step 2: View the JSON**

1. Expand any event by clicking the arrow
2. See the complete JSON structure
3. Notice the different event types (recurring vs single)

### **Step 3: Test Recurring Event Editing**

1. Go to "Enhanced Event System"
2. Add a recurring event
3. Edit it with "Edit This Event Only"
4. Go back to JSON Viewer and see the new single event with `parentEventId`

### **Step 4: Export Data**

1. In JSON Viewer, click the copy icon
2. All data is copied to clipboard
3. Paste it somewhere to see the complete structure

## 🔧 Technical Details

### **File Storage**

- Events are stored in: `events.json`
- Collections are stored in: `event_collections.json`
- Files are saved in the app's documents directory

### **Data Persistence**

- All changes are automatically saved
- Data persists between app sessions
- JSON files can be manually edited if needed

### **Performance**

- Efficient loading with lazy expansion
- Horizontal scrolling for wide JSON content
- Minimal memory usage with virtual scrolling

## 🎉 Benefits for Development

1. **Debug Event Issues**: See exactly how events are stored
2. **Test Recurring Logic**: Verify that "edit this event only" creates proper single events
3. **Data Migration**: Export data for backup or migration
4. **Development Testing**: Add mock data to test features
5. **JSON Validation**: Ensure data structure is correct

## 🚀 Next Steps

Now that you can see the JSON structure, you can:

- Verify that recurring event editing works correctly
- See how individual event modifications are stored
- Test the system with different event types
- Export data for analysis or backup

The JSON viewer gives you complete visibility into how the enhanced event system stores and manages your calendar data!
