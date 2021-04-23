#!/usr/bin/env Rscript
options(warn=-1)
suppressPackageStartupMessages({
    library(optparse)
    library(dplyr)
    library(tidyr)
})

parseargs <- function() {
    option_list = list(
        make_option(c("-a", "--assume"), type="logical", action="store_true",
            default=FALSE, help="assume data has been downloaded")
    );
    opt_parser = OptionParser(option_list=option_list);
    return(parse_args(opt_parser));
}

# Get subset (as requested by instructions) of training data and join it with
# subject and activity datasets
get_train_data <- function() {
    # 2 we only care about observations that are either mean of standard dev.
    colsWeCareAbout <- tbl_df(read.table("UCI HAR Dataset/features.txt", header=FALSE, sep="")) %>%
        # this filters out meanFreq(), which I _think_ is the right thing todo,
        # not 100% though
        filter(grepl("mean\\()|std\\()", V2, ignore.case=TRUE))

    # create a table of activities that is nicely named
    # 3 Uses descriptive activity names to name the activities
    activityLabels <- tbl_df(read.table("UCI HAR Dataset/activity_labels.txt", header=FALSE, sep=""))
    activitesRaw <- tbl_df(read.table("UCI HAR Dataset/train/y_train.txt", header=FALSE, sep=""))
    activites <- dplyr::inner_join(activityLabels, activitesRaw, by = "V1") %>%
        dplyr::select(V2) %>%
        dplyr::rename(Activity=V2)

    # create a table of subjects
    subjects <- tbl_df(read.table("UCI HAR Dataset/train/subject_train.txt", header=FALSE, sep="")) %>%
        dplyr::rename(Subject=V1)

    # read the actual data, subset it based on the columns the intrstructions
    # stated were relvant.
    # Rename all the column headers to something useful
    # Add a column to show this can from the training data set
    data <- tbl_df(read.table("./UCI HAR Dataset/train/X_train.txt", header=FALSE, sep=""))
    data <- data[,colsWeCareAbout$V1]
    data <- data %>% mutate(DataSet="Train", .before=V1) %>%
        rename_at(names(data), ~ c(colsWeCareAbout[,2])[[1]])

    # join all the created datasets and return that data frame
    return(dplyr::bind_cols(subjects, activites, data))
}

# Get subset (as requested by instructions) of testing data and join it with
# subject and activity datasets
get_test_data <- function() {
    # 2 we only care about observations that are either mean of standard dev.
    colsWeCareAbout <- tbl_df(read.table("UCI HAR Dataset/features.txt", header=FALSE, sep="")) %>%
        # this filters out meanFreq(), which I _think_ is the right thing todo,
        # not 100% though
        filter(grepl("mean\\()|std\\()", V2, ignore.case=TRUE))

    # create a table of activities that is nicely named
    # 3 Uses descriptive activity names to name the activities
    activityLabels <- tbl_df(read.table("UCI HAR Dataset/activity_labels.txt", header=FALSE, sep=""))
    activitesRaw <- tbl_df(read.table("UCI HAR Dataset/test/y_test.txt", header=FALSE, sep=""))
    activites <- dplyr::inner_join(activityLabels, activitesRaw, by = "V1") %>%
        dplyr::select(V2) %>%
        dplyr::rename(Activity=V2)

    # create a table of subjects
    subjects <- tbl_df(read.table("UCI HAR Dataset/test/subject_test.txt", header=FALSE, sep="")) %>%
        dplyr::rename(Subject=V1)

    # read the actual data, subset it based on the columns the intrstructions
    # stated were relvant.
    # Rename all the column headers to something useful
    data <- tbl_df(read.table("./UCI HAR Dataset/test/X_test.txt", header=FALSE, sep=""))
    data <- data[,colsWeCareAbout$V1]
    data <- data %>% mutate(DataSet="Test", .before=V1) %>%
        rename_at(names(data), ~ c(colsWeCareAbout[,2])[[1]])

    # join all the created datasets and return that data frame
    return(dplyr::bind_cols(subjects, activites, data))
}

main <- function() {
    opt = parseargs();
    # if -a is passed on the command line, don't try to download or extract the
    # file(s). This is really just an option to speed up local testing
    if (opt$a == FALSE) {
        download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", "data.zip")
        unused <- unzip("data.zip")
    }

    # 1 Merge training and test sets
    # 2 and 3 happen within these functions
    data <- dplyr::bind_rows(get_train_data(), get_test_data())

    # 4 Appropriately labels the data set with descriptive variable names
    names(data) <- gsub("\\()", "", names(data))
    names(data) <- gsub("-", "", names(data))
    names(data) <- gsub("^t", "Time", names(data))
    names(data) <- gsub("^f", "Frequency", names(data))
    names(data) <- gsub("Acc", "Accelerometer", names(data))
    names(data) <- gsub("BodyBody", "Body", names(data))
    names(data) <- gsub("Gyro", "Gyroscope", names(data))
    names(data) <- gsub("Mag", "Magnitude", names(data))
    names(data) <- gsub("mean", "Mean", names(data), ignore.case=TRUE)
    names(data) <- gsub("std", "STD", names(data), ignore.case=TRUE)
    names(data) <- gsub("freq", "Frequency", names(data))
    names(data) <- gsub("angle", "Angle", names(data))
    names(data) <- gsub("gravity", "Gravity", names(data))

    print(data)
    write.table(data, file = "data.txt", row.names=FALSE)

    # 4 creates a second, independent tidy data set with the average of each variable for each activity and each subject.
    avg <- data %>%
        select(-DataSet) %>%
        group_by(Activity, Subject) %>%
        summarise_all(funs(mean))
    # rename all cols that have been averaged to reflect that
    names(avg)[3:68] <- gsub("^", "MeanOf", names(avg)[3:68])

    print(avg)
    write.table(avg, file = "avg.txt", row.names=FALSE)
}

main()
