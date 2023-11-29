﻿CREATE TYPE [dbo].[PartRepairStationsDetailsType] AS TABLE (
    [PartRepairStationsDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PartRepairStationsId]        BIGINT        NOT NULL,
    [City]                        VARCHAR (250) NULL,
    [Country]                     VARCHAR (150) NULL,
    [FacilityId]                  BIGINT        NULL,
    [FacilityName]                VARCHAR (250) NULL,
    [OverhaulPrice]               VARCHAR (250) NULL,
    [OverHTat]                    VARCHAR (50)  NULL,
    [Phone]                       VARCHAR (20)  NULL,
    [PostalCode]                  VARCHAR (50)  NULL,
    [QuoteSpeed]                  VARCHAR (50)  NULL,
    [RepairHTat]                  VARCHAR (20)  NULL,
    [RepairPrice]                 VARCHAR (20)  NULL,
    [State]                       VARCHAR (50)  NULL,
    [TestPrice]                   VARCHAR (20)  NULL,
    [TestTat]                     VARCHAR (20)  NULL,
    [WebLink]                     VARCHAR (150) NULL,
    [Response]                    VARCHAR (250) NULL);

