CREATE TABLE [dbo].[ATAALL] (
    [ATAID]                        BIGINT        IDENTITY (1, 1) NOT NULL,
    [Category]                     VARCHAR (100) NULL,
    [ATA_Chapter]                  VARCHAR (100) NULL,
    [Chapter_Description]          VARCHAR (100) NULL,
    [ATA_Concatenated_View]        VARCHAR (100) NULL,
    [Sub_Chapter]                  VARCHAR (100) NULL,
    [SubChapter_Description]       VARCHAR (100) NULL,
    [SubChapter_Concatenated_View] VARCHAR (100) NULL
);

