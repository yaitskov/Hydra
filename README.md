Hydra Framework
===============

An all-in-one framework for writing Haskell apps which use the following features out of the box:

- Multithreading
- Safe STM-powered concurrency
- KV DB functionality (Redis & RocksDB backends supported)
- SQL DB functionality (beam incorporated, SQLite supported, PG & MySQL possible)
- Logging
- Random data generation
- Many others

With the framework, you can create complex applications that have a good maintainability, testability, simplicity, that have a good structure and are easy to read and change. The key principles in the framework:

- Layered architecture
- Separation of Subsystem Interfaces, Business Logic, Runtime and Implementation
- Convenient and simple to use eDSLs for Business Logic
- Layered structure of business application: State, Domain, Business Logic

The Hydra Project
=================

This project demonstrates the principles of Software Design and Architecture in pure Functional Programming. It provides a framework implemented with several different approaches for easy comparison:

- Final Tagless
- Free Monad
- Church Encoded Free Monad

The project is a showcase for my book [Functional Design and Architecture](https://graninas.com/functional-design-and-architecture-book/). The approaches presented in Hydra are well-described and rationalized in the book, so you may obtain even more info about best practices and ideas of how to write a good Haskell code.

Sample applications
===================

There are 3 sample applications:
* [Astro app](app/astro): web server (with servant) and CLI client tool which allows to track meteors (tool for astronomers).
* [PerfTestApp](app/PerfTestApp): an application you can run to measure the performance of the three engines.
* [MeteorCounter](app/MeteorCounter): application which demonstrates the usage of STM and multithreading using three engines.

Sample SQL-related code
=======================

```haskell
createMeteor :: MeteorTemplate -> D.SqlConn BS.SqliteM -> L.AppL MeteorId
createMeteor mtp@(MeteorTemplate {..}) conn = do
  L.logInfo $ "Inserting meteor into SQL DB: " <> show mtp

  let time = Time.UTCTime (toEnum 1) (Time.secondsToDiffTime 0)

  doOrFail
    $ L.scenario
    $ L.runDB conn
    $ L.insertRows
    $ B.insert (SqlDB._meteors SqlDB.astroDb)
    $ B.insertExpressions
          [ SqlDB.Meteor B.default_
            (B.val_ size)
            (B.val_ mass)
            (B.val_ azimuth)
            (B.val_ altitude)
            (B.val_ time)
          ]

  let predicate meteorDB
          = (SqlDB._meteorSize meteorDB     ==. B.val_ size)
        &&. (SqlDB._meteorMass meteorDB     ==. B.val_ mass)
        &&. (SqlDB._meteorAzimuth meteorDB  ==. B.val_ azimuth)
        &&. (SqlDB._meteorAltitude meteorDB ==. B.val_ altitude)

  m <- doOrFail
    $ L.scenario
    $ L.runDB conn
    $ L.findRow
    $ B.select
    $ B.limit_ 1
    $ B.filter_ predicate
    $ B.all_ (SqlDB._meteors SqlDB.astroDb)
  pure $ SqlDB._meteorId $ fromJust m
```

**Additional materials describing these ideas:**

- [Hierarchical Free Monads and Software Design in Functional Programming (Talk, Eng)](https://www.youtube.com/watch?v=3GKQ4ni2pS0) | [Slides (Eng)](https://docs.google.com/presentation/d/1SYMIZ-LOI8Ylykz0PTxwiPuHN_02gIWh9AjJDO6xbvM/edit?usp=sharing)
- [Final Tagless vs Free Monad (Talk, Rus)](https://www.youtube.com/watch?v=u1GGqDQyGfc) | [Slides (Eng)](https://docs.google.com/presentation/d/1VhS8ySgk2w5RoN_l_Ar_axcE4Dzf97zLw1uuzUJQbCo/edit?usp=sharing)
- [Automatic Whitebox Testing with Free Monads (Talk, Eng)](https://www.youtube.com/watch?v=-cp2BDlwi-M) | [Slides (Eng)](https://docs.google.com/presentation/d/1KJj0OIUdSmkEmWo_u0P1ZyCw28wqpNx8VXClKjpIzEo/edit?usp=sharing)
- [Automatic whitebox testing with Free Moands (Showcase, Article)](https://github.com/graninas/automatic-whitebox-testing-showcase)

### Special Thanks

Special thanks to these folks who made a good contribution into Hydra directly or indirectly:
* [Alexander Vershilov](https://github.com/qnikst)
* [Vasily Gorev](https://github.com/C37H40O9)
* [Sergey Stepanenko](https://github.com/Kaptch)
* [Kirill Havryliuk](https://github.com/kirill-havryliuk)
* [Vladislav Sabanov](https://github.com/willbasky)
* [Evgeniy Tokarev](https://github.com/strobe)
