Data Organization
=================
Every behavioral science dataset is unique, not only in terms of what data are collected but also in how they are most naturally structured for collection and analysis. The structure and organization of a dataset are determined by, among other factors, the scientific questions to be asked of it. Data collection and analysis software frequently impose certain assumptions on the structure of a dataset; for example, a hierarchical organization of subject at the top level, followed by session, followed by trial. While this structure facilitates data analysis aimed at many common scientific questions, some questions are poorly served by this format; for example, questions primarily about two-subject interactions.

A typical hierarchically-organized dataset may have a structure like this:

* Subject 1
    * Data such as age, sex, education level, etc.
    * Session 1
        * Data such as date, time, task parameters, etc.
        * Trial 1
            * Data such as stimulus, response, etc.
        * Trial 2
        * Additional trials...
    * Session 2
        * Session data as above
        * Trials as above...
    * Additional sessions...
* Subject 2
    * Subject data as above
    * Sessions as above...
* Additional subjects...

Relational databases offer a standard, well-understood framework for representing complex datasets in a flat structure. In the abstract, a relational database consists of multiple tables, each of which is conceptually at the same hierarchical level. Each table consists of multiple columns (also called fields) identifying the various types of data collected for each observation, and multiple rows representing the observations. By using columns of corresponding values across different tables (sometimes called "foreign keys"), the data in the various tables can be related to each other, and the connections captured by a hierarchical structure can also be represented in tabular form.

A dataset organized in a relational database may have a structure like this:

: Subjects

| SubjectID | Age | Sex | Education    |
|-----------|-----|-----|--------------|
| 1         | 20  | F   | Some college |
| 2         | 25  | M   | Bachelors    |

: Sessions

| SessionID | SubjectID | Date      | Time  |
|-----------|-----------|-----------|-------|
| 1         | 1         | 2017-7-10 | 10:30 |
| 2         | 1         | 2017-7-17 | 11:15 |
| 3         | 2         | 2017-7-11 | 13:00 |
| 4         | 3         | 2017-7-11 | 14:00 |

: Trials

| SessionID | TrialNumber | StimulusID | Response |
|-----------|-------------|------------|----------|
| 1         | 1           | 1          | L        |
| 1         | 2           | 2          | R        |
| 1         | 3           | 1          | R        |

The relationship between a subject and the subject's session is identified by the common SubjectID column, and between session and trial by the common SessionID column.

Relational databases are often considered in terms of specific database software, such as MySQL or Microsoft Access, but these specialized software platforms have a relatively high barrier to entry, both cost (for commercial products) and learning curve. However, the table-like structure of a relational database can be captured in a wide range of formats. Indeed, many behavioral science datasets are often recorded in spreadsheets that capture many elements of relational database design. Unfortunately, the most popular spreadsheet software, Microsoft Excel, has a variety issues that make it unsuitable for usage with scientific datasets (cite). The safest and most flexible way to store tabular data remains plain-text formats such as the popular CSV (comma-separated values) file format, and a collection of such files can represent most behavioral datasets in a relational database structure.

However, during data acquisition, it is often more natural to consider data organization schemata that reflect the way experiments are performed and data are collected. This is typically better reflected by the hierarchical approach, with data collected from individual experimental sessions collected together. The **objective** of this document is to establish a standard means of organizing data according to either hierarchical, tabular, or mixed structures, which facilitates the reorganization of data into the more flexible relational organization.

Terminology
-----------

* Dataset
    * A collection of observations associated with a project
* Data group, table
    * A collection of observations of the same type
* Record
    * A tuple (or list of items) representing a single observation
* Metadata
    * Information describing the structure and nature of the dataset.

Approach
--------

Files containing the records and metadata for a dataset are organized in a project directory and its subdirectories.

### Tabular data groups

A data group can be represented as a single table of records, with no children. In this case, it is stored as a single file, named `<GroupName>.<format>`. Valid formats are:

* `csv`
    * Entries are separated by commas, `,`, and may optionally be enclosed by single `'` or double `"` quotes. A column name header row must be included.
* `csv2`
    * As `csv`, but entries are separated by semicolons `;`. This format is frequently used in language environments where commas are used as the decimal separator.
* `tsv`
    * As `csv`, but entries are separated by tab characters.
* `wsv`
    * As `csv`, but entries are separated by one or more whitespace characters.
* `table`
    * As `csv`, but entries are separated by a comma, semicolon, or whitespace character, followed by zero or more whitespace characters.
* `json`
    * A JSON-formatted file containing an array of objects, each representing one record.
* `yaml`, `yml`
    * A YAML-formatted file containing an array of mappings, each representing one record.

### Hierarchical data groups

A data group can also be represented as a set of records, each of which can have one or more children which inherit values from the parent. In this case, the data group is represented by a set of files in a directory tree.

For an illustrative example, consider a data group of subjects, each of which provides data for one or more sessions, each of which is a simple record. Such a group could be represented with the following directory tree:

* `subjects/`
    * `subj-1a7/`
        * `subj-1a7.record.table`
            ```
            SubjectID  Age  EducationLevel
            1a7        28   College
            ```
        * `sessions.table`
            ```
            Date        StartTime  Task
            2017-07-08  13:00      Stroop
            2017-07-12  11:20      "Wisconsin card sort"
            ```
    * `subj-3b8/`
        * `subj-3b8.record.table`
            ```
            SubjectID  Age  EducationLevel
            3b8        19   "Some college"
            ```
        * `sessions.table`
            ```
            Date        StartTime  Task
            2017-06-28  13:45      Stroop
            ```
    * `subj-2c1/`
        * `subj-2c1.record.table`
            ```
            SubjectID  Age  EducationLevel
            2c1        32   Postgraduate
            ```
