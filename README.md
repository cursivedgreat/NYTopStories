

#  NYTopStories

NYTopStories is an iOS app which list down articles from your favorite section.

## Steps to run

Download and unzip. In your terminal move to app folder.
Run the commond (Can be skipped as code contains installed pod and api key)

```bash
pod install
```

Once completed, run the command 

```bash
open NYTopStories.xcworkspace
```

to open NYTopStories in Xcode

## Model
`ViewModel.swift` is the model for the listing and detailing of articles. This also manages all the network call and structuring of data completely seperate from any View or Controller.  This is not bound to any View or Controller. Hence it very easy to seperate model and associated logic from View and Controller. It also helps  in maintaining code and write simple test cases. All the model object used are struct just to have each view or controller its own copy.


##  View - Controller
`ListViewController.swift` and `DetailViewController.swift` are two ViewController used here. ListViewController uses `ViewModel` as its model and DetailViewController uses `Results` struct as its model. 

Architecture of `ViewModel.swift, ListViewController.swift and its storyboard` is such that this pattern can exist throughout without any overlapping. If required whole patten can be moved, shifted or copied without much code changes and associated regression in code. Associated test case also will not require much changes. Hence it offers great flexibilty. This pattern is such that all the feature can broken down to this type of pattern easily. In a feature or module, all the pattern will be mostly independent of each other that offers great depth of scalability.

## Database
`Database.swift` is a single file where all the database related classes exists. `SQLiteDatabase` is main class that handles all the database operations.
It has a class method `open(path dbPath: String) throws -> SQLiteDatabase` that return its instance if database opens successfully. Other public instance method `save(response aResponse: ApiResponse) throws`  is used to persist table data(Currenlty only decoded response). Other instance method `func query() throws -> ApiResponse` retrieve the cached response. A protocol `SQLTable` is also defined that all the table in the database must adhere to. 

## Network call
`RequestManager.swift` is a single class that can be expanded to handle all network related call.

## API Call Mock
`URLSessionMock.swift` has all the ingredient to mock a network call without hitting actual network.

## Common.swift
This file can be considered be a common place of the global variable and functions.

## Stub Code
Current `Database.swift`, `RequestManager.swift`, `URLSessionMock.swift` etc can be used as stubs code to quickely start any project.

## Licence
[MIT](https://choosealicense.com/licenses/mit/)
