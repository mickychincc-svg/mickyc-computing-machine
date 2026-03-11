// TrackFlow.xcdatamodeld
// This file documents the CoreData schema.
// In Xcode, create a new Data Model file named "TrackFlow" and add these entities.

/*
 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: UserProfile                                      │
 │  Attributes:                                              │
 │    id        : UUID   (required)                          │
 │    email     : String (required)                          │
 │    name      : String (required)                          │
 │    createdAt : Date   (required)                          │
 └──────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: Task                                             │
 │  Attributes:                                              │
 │    id          : UUID    (required)                       │
 │    title       : String  (required)                       │
 │    taskDescription : String                               │
 │    createdAt   : Date    (required)                       │
 │    completedAt : Date                                     │
 │    isCompleted : Boolean (required, default: false)       │
 │    userID      : String  (required)                       │
 │  Relationships:                                           │
 │    stages      : [Stage]  (to-many, cascade delete)       │
 └──────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: Stage                                            │
 │  Attributes:                                              │
 │    id        : UUID   (required)                          │
 │    name      : String (required)                          │
 │    dueDate   : Date                                       │
 │    status    : String (required, default: "pending")      │
 │    order     : Int32  (required)                          │
 │  Relationships:                                           │
 │    task      : Task   (to-one, inverse: stages)           │
 │    updates   : [StageUpdate] (to-many, cascade delete)    │
 │    dailyNotes: [DailyNote]   (to-many, cascade delete)    │
 └──────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: StageUpdate                                      │
 │  Attributes:                                              │
 │    id        : UUID   (required)                          │
 │    status    : String (required)                          │
 │    note      : String (required)                          │
 │    date      : Date   (required)                          │
 │  Relationships:                                           │
 │    stage     : Stage  (to-one, inverse: updates)          │
 └──────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: DailyNote                                        │
 │  Attributes:                                              │
 │    id        : UUID   (required)                          │
 │    content   : String (required)                          │
 │    date      : Date   (required)                          │
 │  Relationships:                                           │
 │    stage     : Stage  (to-one, inverse: dailyNotes)       │
 └──────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────────────────────────┐
 │  ENTITY: Reminder                                         │
 │  Attributes:                                              │
 │    id           : UUID   (required)                       │
 │    title        : String (required)                       │
 │    reminderNote : String                                  │
 │    date         : Date   (required)                       │
 │    type         : String (required)                       │
 │    recurrence   : String (required, default: "none")      │
 │    userID       : String (required)                       │
 └──────────────────────────────────────────────────────────┘
*/
