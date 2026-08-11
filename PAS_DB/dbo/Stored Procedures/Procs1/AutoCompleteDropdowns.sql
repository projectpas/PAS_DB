/* =====================================================================
 PN-17009 : AutoCompleteDropdown SP consolidation + Stock/Non-Stock label

 Updated SPs only (2 objects) - safe to run standalone against an
 environment that already has the PN-17008/PN-17009 ItemMaster/Stockline
 changes applied.

 1) dbo.AutoCompleteDropdowns
    - All 3 branches keyed on @TableName='ItemMasterNonStock' now query
      dbo.ItemMaster WHERE ISNULL(IsNonStock,0) = 1 instead of the retired
      dbo.ItemMasterNonStock table.
    - Value now returns ItemMasterId (previously returned MasterPartId,
      which the callers were already mapping into an "itemMasterId" field -
      this was a latent bug once non-stock rows moved into ItemMaster with
      their own ItemMasterId). No Angular changes needed: the callers
      (stock-line-setup.component.ts, non-stock-line-setup.component.ts,
      po-setup.component.ts) already pass 'ItemMasterNonStock' as the
      table-name literal and consume Value as itemMasterId.
    - Label now ends with ' (Non-Stock)' for these branches, and with
      ' (Stock)' for the existing @TableName='ItemMaster' branches (both
      the Count='0' and Count<>'0' code paths), matching the rule:
        with manufacturer -> "PartNumber - Manufacturer (Stock|Non-Stock)"
        without manufacturer -> "PartNumber (Stock|Non-Stock)"
    - NOT changed: @TableName='ItemMasterALL' (still IsNonStock=0 only) and
      the two @IsFromUpload=1 branches (label kept as plain PartNumber,
      since upload/import matching relies on an exact-text match and a
      decorative suffix would break it). Flagging both for your review -
      let me know if ItemMasterALL should now include Non-Stock rows too.

 2) dbo.AutoCompleteDropdownsItemMasterWithManufacturer
    - This SP only ever returns IsNonStock=0 (Stock) rows already (added
      under PN-17008). Appended ' (Stock)' to its Label output (all 4
      SELECT blocks) so the two label conventions stay consistent - this
      is the SP actually hit by the Stock branch of loadPartNumData(),
      loadRevicePnPartNumData() and loadOemPnPartNumData() in
      stock-line-setup.component.ts via
      commonService.autoCompleteSmartDropDownItemMasterWithManufacturer(...).

 NOT included in this file (unchanged, flagged only):
    - dbo.AutoCompleteDropdownsItemMasterWithManufacturerIsLot: same label
      pattern, always Stock-only (lot-based lookup - non-stock items are
      never lotted), left untouched. Let me know if you want the same
      ' (Stock)' suffix applied here too for full consistency.

 Author : RAJESH GAMI
 Date   : 13/July/2026
===================================================================== */

-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.AutoCompleteDropdowns
-- ---------------------------------------------------------------------------------------------------
/*************************************************************
 ** File:   [AutoCompleteDropdowns]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to search part
 ** Purpose:
 ** Date:   06/14/2024

 ** PARAMETERS:
 @UserType varchar(60)

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		        Change Description
 ** --   --------     -------		        --------------------------------
    1    06/14/2024   Vishal Suthar		    Added History
    2    06/14/2024   Vishal Suthar		    Increased Limit of records from 20 to 50 for Item Master Module
    3    10/03/2024   Devendra Shekh	    Added case for BatchDetails
	4    21/03/2024   BHARGAV SALIYA	    Added case for Stockline
	5    31/12/2024   Devendra Shekh	    Added field IsSerialized for ItemMaster Table
	6    03/01/2025   Moin Bloch  	        Added field IsTravelerTask, StandardHours, StandardMinute for Task Table
	7    10/01/2025   Sahdev Saliya         Added Defult site as per setting while add new item
	8    24/01/2025   Sahdev Saliya         Added According To The Default Site Management Structure When Adding New items
    9    10/Feb/2025  RAJESH GAMI  	        Return fields: IsPrintInspector, IsPrintTechnician for Task Table
	10   14/Feb/2025  RAJESH GAMI  	        Return fields: PublicationTemplate  for PublicationType Table
	11   19/Feb/2025  AMIT GHEDIYA  	    Added case for TaxType table.
	12   11/Mar/2025  AMIT GHEDIYA          Added case for VendorOrderType table.
	13   31/Mar/2025  Sahdev Saliya         Added case for EmployeeCertifyingStaff table.
	14	 01/Mar/2025  Devendra Shekh	    Modified (For Task Table - Order By Description ASC)
	15   14/Apr/2025  Moin Bloch	        Modified (Added field IsOEM for ItemMaster Table)
	16   28/04/2025   Moin Bloch	        Modified (Order By [Sequence] ASC)
	17   26/08/2025   Moin Bloch	        Modified (Added field IsPrintAdmin for Task Table)
    18   25/11/2025   Ayushi Patel          Escaped table name in dynamic SQL (added [] around @TableName) to support reserved names like Percent.
    19   03/12/2025   Ayushi Patel          Removed brackets from @TableName to avoid double [[TableName]] in dynamic SQL.
    20   16/12/2025   Ayushi Patel  	    Return fields: SalesOrderQuote for SalesOrderQuote Table
    21   20-Dec-2025  Divyesh Kathiriya  	Added case for Warehouse,Location,Shelf,Bin
    22   30/01/2026   Ayushi Patel          Added Vendor auto-suggestion logic with duplicate VendorName handling (append VendorCode when duplicates exist)
    23   13/05/2026   Ayushi Patel  	    [PN-16321]return partdescription for itemMasterAll
	24   20/05/2026   Moin Bloch  	        Added case for MaintenanceCategory table. PN-16449
	25   21/04/2026   Sahdev Saliya			Display Only Trainer Expertise EMPLOYEE list for EMP TRAINER SCREEN(PN-16113)
	26    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

	26   09/07/2026   AMIT GHEDIYA			Get for EngineRegistryHeader table merge for dropdown
	27   13/July/2026  RAJESH GAMI			[PN-17009] Retired dbo.ItemMasterNonStock table lookups (@TableName='ItemMasterNonStock', 3 branches):
											redirected to dbo.ItemMaster WHERE ISNULL(IsNonStock,0)=1, Value now returns ItemMasterId
											(previously MasterPartId) to stay consistent with the merged Stock ItemMaster branches.
											Also appended ' (Stock)'/' (Non-Stock)' to the Label output for the ItemMaster and
											ItemMasterNonStock branches so callers can distinguish item type in the dropdown text.
    28   31/July/2026  Ayushi Patel         [PN-17489][Item Accounting Type filter] Added dedicated @TableName='InventoryGLSetting'(IsStock=1) and @TableName='InventoryGLSettingNonStock' (IsStock=0)
    29   05-Aug-2026   Bhargav Saliya       [PN-17562] Part Number search (Item Master dropdown): normalize dashes/slashes
    30   05-Aug-2026   Bhargav Saliya       [PN-17609] Added Oreder By For Site DATA

--select * from dbo.Employee
--EXEC AutoCompleteDropdowns 'ItemMasterALL','ItemMasterId','PartDescription','',1,0,'',1,0
--EXEC AutoCompleteDropdowns 'Vendor','VendorId','VendorName','',1,20,'0',1
**************************************************************/
CREATE    PROCEDURE [dbo].[AutoCompleteDropdowns]
	@TableName VARCHAR(50) = NULL,
	@Parameter1 VARCHAR(50) = NULL,
	@Parameter2 VARCHAR(100) = NULL,
	@Parameter3 VARCHAR(50) = NULL,
	@Parameter4 BIT = TRUE,
	@Count VARCHAR(10) = 0,
	@Idlist VARCHAR(MAX) = '0',
	@MasterCompanyId INT,
	@IsFromUpload BIT = 0
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
        DECLARE @Sql NVARCHAR(MAX);

        SET @TableName = LTRIM(RTRIM(@TableName));
        SET @TableName = REPLACE(REPLACE(@TableName, '[', ''), ']', '');

		DECLARE @TrainerExpertiseId INT =0;
		IF(@TableName='EmpTrainer')
		BEGIN
			SET @TrainerExpertiseId = (SELECT TOP 1 EmployeeExpertiseId FROM DBO.EmployeeExpertise WITH(NOLOCK) WHERE EmpExpCode  = 'Trainer')
		END

        CREATE TABLE #TempTable (
			Value BIGINT,
			Label VARCHAR(MAX),
			MasterCompanyId int
		)

		IF(@Count='0')BEGIN
            print '00'
            IF(@TableName='Employee')BEGIN
                IF(@Parameter4=1)BEGIN
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(FirstName LIKE '%'+@Parameter3+'%' OR LastName LIKE '%'+@Parameter3+'%'))
                    UNION
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EmployeeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                    ORDER BY FirstName+' '+LastName
                END
                ELSE BEGIN
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND FirstName LIKE '%'+@Parameter3+'%' OR LastName LIKE '%'+@Parameter3+'%'
                    UNION
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EmployeeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
            END
			ELSE IF(@TableName='EngineRegistryHeader')BEGIN
                IF(@Parameter4=1)BEGIN
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName+' '+EngineModel AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(SerialNum LIKE '%'+@Parameter3+'%' OR EngineName LIKE '%'+@Parameter3+'%'))
                    UNION
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EngineRegistryId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                    ORDER BY SerialNum+' '+EngineName+' '+EngineModel
                END
                ELSE BEGIN
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName+' '+EngineModel AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND SerialNum LIKE '%'+@Parameter3+'%' OR EngineName LIKE '%'+@Parameter3+'%'
                    UNION
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EngineRegistryId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
            END
			ELSE IF (@TableName='EmpTrainer')
			BEGIN
				SELECT DISTINCT e.EmployeeId AS Value, e.FirstName+' '+e.LastName AS Label
				FROM dbo.Employee e WITH(NOLOCK)
				WHERE e.MasterCompanyId=@MasterCompanyId AND ISNULL(e.IsDeleted,0)=0
				  AND EXISTS (SELECT 1 FROM STRING_SPLIT(e.EmployeeExpIds,',') s WHERE TRY_CAST(s.value AS INT)=@TrainerExpertiseId)
				  AND (
						(@Parameter4=1 AND (e.IsActive=1 AND (e.FirstName LIKE '%'+@Parameter3+'%' OR e.LastName LIKE '%'+@Parameter3+'%')))
					 OR (@Parameter4<>1 AND (e.IsActive=1 AND (e.FirstName LIKE '%'+@Parameter3+'%' OR e.LastName LIKE '%'+@Parameter3+'%')))
					 OR e.EmployeeId IN (SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@Idlist,','))
				  )
				ORDER BY Label;
			 END
			 ELSE IF(@TableName='PublicationType')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY Name asc
                     END
                     ELSE
					 BEGIN
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND Description LIKE '%'+@Parameter3+'%'
                         UNION
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY Name asc
                     END
            END
			ELSE IF(@TableName='MaintenanceCategory')
			BEGIN
				IF(@Parameter4=1)
				BEGIN
                         SELECT DISTINCT MtcCategoryId as Value, [MtcCategory] as Label, MaintenanceCode
                         FROM dbo.MaintenanceCategory P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(MtcCategory LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT MtcCategoryId as Value, [MtcCategory] as Label, MaintenanceCode
                         FROM dbo.MaintenanceCategory P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND MtcCategoryId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [MtcCategory] asc
                     END
                     ELSE
					 BEGIN
                         SELECT DISTINCT MtcCategoryId as Value, [MtcCategory] as Label, MaintenanceCode
                         FROM dbo.MaintenanceCategory P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND MtcCategory LIKE '%'+@Parameter3+'%'
                         UNION
                         SELECT DISTINCT MtcCategoryId as Value, [MtcCategory] as Label, MaintenanceCode
                         FROM dbo.MaintenanceCategory P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND MtcCategoryId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [MtcCategory] asc
                     END
            END
            ELSE IF(@TableName='Task')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence, IsTravelerTask, StandardHours, StandardMinute, Resolution, Descrepancy, IsPrintInWO, IsPrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence , IsTravelerTask, StandardHours, StandardMinute, Resolution, Descrepancy, IsPrintInWO, IsPrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND TaskId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
                     END
                     ELSE
					 BEGIN
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence, IsTravelerTask, StandardHours, StandardMinute
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND Description LIKE '%'+@Parameter3+'%'
                         UNION
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence, IsTravelerTask, StandardHours, StandardMinute
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND TaskId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
                     END
            END
            ELSE IF(@TableName='ConsigneeLot')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.LOT WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                         UNION
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.Lot WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                         ORDER BY LotId DESC
                     END
                     ELSE BEGIN
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.LOT WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                         UNION
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.Lot WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                         ORDER BY LotId DESC
                     END
            END
            ELSE IF(@TableName='LotLatest')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.LOT WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.Lot WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY LotId DESC
                     END
                     ELSE BEGIN
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.LOT WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT LotId AS Value, LotNumber AS Label
                         FROM dbo.Lot WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY LotId DESC
                     END
            END
			ELSE IF(@TableName='EmployeeCertifyingStaff')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT IsCertifyingStaff AS Value, Description AS Label
                         FROM dbo.EmployeeCertifyingStaff WITH(NOLOCK)
                         WHERE (IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT IsCertifyingStaff AS Value, Description AS Label
                         FROM dbo.EmployeeCertifyingStaff WITH(NOLOCK)
                         WHERE IsCertifyingStaff IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY IsCertifyingStaff DESC
                     END
                     ELSE BEGIN
                         SELECT DISTINCT IsCertifyingStaff AS Value, Description AS Label
                         FROM dbo.EmployeeCertifyingStaff WITH(NOLOCK)
                         WHERE (IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT IsCertifyingStaff AS Value, Description AS Label
                         FROM dbo.EmployeeCertifyingStaff WITH(NOLOCK)
                         WHERE IsCertifyingStaff IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY IsCertifyingStaff DESC
                     END
            END
            ELSE IF(@TableName='SalesOrderQuote')BEGIN
                        IF(@Parameter4=1)BEGIN
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND IsNewVersionCreated = 0 AND(SalesOrderQuoteNumber LIKE '%'+@Parameter3+'%'))
                                 UNION
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND IsNewVersionCreated = 0 AND SalesOrderQuoteId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                 ORDER BY SalesOrderQuoteId DESC
                        END
                        ELSE BEGIN
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0
                                 AND IsNewVersionCreated = 0 AND(SalesOrderQuoteNumber LIKE '%'+@Parameter3+'%'))
                                 UNION
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND IsNewVersionCreated = 0
                                 AND SalesOrderQuoteId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                 ORDER BY SalesOrderQuoteId DESC
                            END
                        END
            ELSE IF(@TableName='Warehouse')
            BEGIN
                SELECT DISTINCT [WarehouseId] AS Value, [Name] AS Label
                FROM [DBO].[Warehouse] WITH(NOLOCK)
                WHERE [MasterCompanyId] = @MasterCompanyId AND [SiteId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
                ORDER BY [WarehouseId] ASC
            END
            ELSE IF(@TableName='Location')
            BEGIN
                SELECT DISTINCT [LocationId] AS Value, [Name] AS Label
                FROM [DBO].[Location] WITH(NOLOCK)
                WHERE [MasterCompanyId] = @MasterCompanyId AND [WarehouseId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
                ORDER BY [LocationId] ASC
            END
            ELSE IF(@TableName='Shelf')
            BEGIN
                SELECT DISTINCT [ShelfId] AS Value, [Name] AS Label
                FROM [DBO].[Shelf] WITH(NOLOCK)
                WHERE [MasterCompanyId] = @MasterCompanyId AND [LocationId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
                ORDER BY [ShelfId] ASC
            END
            ELSE IF(@TableName='Bin')
            BEGIN
                SELECT DISTINCT [Binid] AS Value, [Name] AS Label
                FROM [DBO].[Bin] WITH(NOLOCK)
                WHERE [MasterCompanyId] = @MasterCompanyId AND [ShelfId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
                ORDER BY [Binid] ASC
            END
			ELSE IF(@TableName='NumberOfEngines')
            BEGIN
                SELECT DISTINCT [Id] AS Value, [Number] AS Label
                FROM [DBO].[NumberOfEngines] WITH(NOLOCK)
                ORDER BY [Id] ASC
            END
            ELSE BEGIN
                     IF(@Parameter4=1)BEGIN
                         IF(@TableName='ItemMaster' AND ISNULL(@IsFromUpload,0) = 0)BEGIN
                             SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, (im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                           FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                           WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Stock)') AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
                             FROM dbo.ItemMaster IM
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                              AND ISNULL(IM.IsNonStock,0) = 0
                              UNION
                             SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber, (im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                    FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                    WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Stock)') AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
                             FROM dbo.ItemMaster IM
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                          AND ISNULL(IM.IsNonStock,0) = 0
                              END
						 ELSE IF(@TableName='ItemMaster' AND ISNULL(@IsFromUpload,0) = 1)
							BEGIN
								SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, im.partnumber AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
								 FROM dbo.ItemMaster IM
								 WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
								  AND ISNULL(IM.IsNonStock,0) = 0
								  UNION
								 SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber, im.partnumber AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
								 FROM dbo.ItemMaster IM
								 WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
							 AND ISNULL(IM.IsNonStock,0) = 0
								  END
                         ELSE IF(@TableName='ItemMasterALL')BEGIN
                                  SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,IM.PartDescription AS PartDescription, im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                         FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                         WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END) AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                                   AND ISNULL(IM.IsNonStock,0) = 0
                                   UNION
                                  SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,IM.PartDescription AS PartDescription, im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                         FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                         WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END) AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                          AND ISNULL(IM.IsNonStock,0) = 0
                                   END
                         ELSE IF(@TableName='ConsigneeLot')BEGIN
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.LOT WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                                  UNION
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.Lot WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                                  ORDER BY LotId DESC
                         END
                         ELSE IF(@TableName='LotLatest')BEGIN
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.LOT WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))
                                  UNION
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.Lot WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                  ORDER BY LotId DESC
                         END
                         ELSE IF(@TableName='ItemMasterNonStock')BEGIN
                                  SELECT IM.ItemMasterId as Value, IM.partnumber as PartNumber, (IM.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                            FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                            WHERE IM.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0)=1)>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Non-Stock)') AS Label, IM.MasterCompanyId, IM.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE IM.MasterCompanyId=@MasterCompanyId AND ISNULL(IM.IsActive, 1)=1 AND ISNULL(IM.IsDeleted, 0)=0 AND (IM.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                                   AND ISNULL(IM.IsNonStock,0) = 1
                         END
                         ELSE IF(@TableName='InventoryGLSetting')BEGIN
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=1 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                                UNION
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=1 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                ORDER BY StockInventoryName asc
                         END
                         ELSE IF(@TableName='InventoryGLSettingNonStock')BEGIN
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=0 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                                UNION
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=0 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                ORDER BY StockInventoryName asc
                         END
                         ELSE IF(@TableName='LotConsignment')BEGIN
                                  SELECT LC.ConsignmentId AS Value, LC.ConsignmentNumber AS Label, LC.MasterCompanyId AS MasterCompanyId, LC.ConsigneeName AS ConsigneeName
                                  FROM dbo.LotConsignment LC
                                  WHERE LC.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND LC.ConsignmentNumber like '%'+@Parameter3+'%'
                         END
						 ELSE IF(@TableName='Site')BEGIN
                             SELECT IM.SiteId as Value, Im.Name as Label, IM.MasterCompanyId, IM.IsDefault IsSerialized,
							 STUFF((SELECT ', ' + CAST(ManagementStructureId AS VARCHAR(100)) [text()]
							 FROM ManagementSite WITH(NOLOCK)
							 WHERE SiteId = IM.SiteId FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),1,2,' ') List_Output
                             FROM dbo.Site IM WITH(NOLOCK)
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(im.IsActive, 1)=1 AND ISNULL(im.IsDeleted, 0)=0 AND Im.Name like '%'+@Parameter3+'%'
                             UNION
                             SELECT IM.SiteId as Value, Im.Name as Label, IM.MasterCompanyId, IM.IsDefault IsSerialized,
							 STUFF((SELECT ', ' + CAST(ManagementStructureId AS VARCHAR(100)) [text()]
							 FROM ManagementSite WITH(NOLOCK)
							 WHERE SiteId = IM.SiteId FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),1,2,' ') List_Output
                             FROM dbo.Site IM WITH(NOLOCK)
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.SiteId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                             ORDER BY Label
                         END
						  ELSE IF(@TableName='PublicationType')BEGIN
                                  SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND([NAME] LIKE '%'+@Parameter3+'%'))
                                  UNION
                                  SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                  ORDER BY PublicationTypeId DESC
                         END
						  ELSE IF(@TableName = 'TaxType') BEGIN
							  SELECT TY.TaxTypeId as Value, TY.Description as Label, TY.Code
								 FROM dbo.TaxType TY WITH(NOLOCK)
							  WHERE TY.MasterCompanyId=@MasterCompanyId AND TY.IsActive = 1 AND TY.IsDeleted = 0;
						 END
						 ELSE IF(@TableName = 'VendorOrderType') BEGIN
							  SELECT VT.VendorOrderTypeId as Value, VT.OrderTypeName as Label
								 FROM dbo.VendorOrderType VT WITH(NOLOCK)
							  WHERE VT.IsActive = 1 AND VT.IsDeleted = 0;
						 END
						 ELSE IF(@TableName = 'VendorAuditType') BEGIN
							  SELECT VAT.VendorAuditTypeId as Value, VAT.VendorAuditType as Label
								 FROM dbo.VendorAuditType VAT WITH(NOLOCK)
							  WHERE VAT.MasterCompanyId=@MasterCompanyId AND VAT.IsActive = 1 AND VAT.IsDeleted = 0;
						 END
                         ELSE IF(@TableName='SalesOrderQuote')BEGIN
                                 SELECT DISTINCT TOP 20 SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND IsNewVersionCreated = 0 AND(SalesOrderQuoteNumber LIKE '%'+@Parameter3+'%'))
                                 UNION
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND IsNewVersionCreated = 0 AND SalesOrderQuoteId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                 ORDER BY SalesOrderQuoteId DESC
                        END
                        ELSE IF(@TableName='Vendor' AND ISNULL(@IsFromUpload,0)=0)BEGIN
                                SELECT TOP 50 V.VendorId AS Value,V.VendorName,V.VendorName+(CASE WHEN(SELECT COUNT(1)
                                                                                             FROM dbo.Vendor VD WITH(NOLOCK)
                                                                                             WHERE VD.VendorName=V.VendorName AND VD.MasterCompanyId=@MasterCompanyId)>1 THEN ' - '+V.VendorCode ELSE '' END) AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH(NOLOCK) WHERE V.MasterCompanyId=@MasterCompanyId AND ISNULL(V.IsActive,1)=1 AND ISNULL(V.IsDeleted,0)=0 AND V.VendorName LIKE '%'+@Parameter3+'%'
                                UNION
                                SELECT V.VendorId AS Value,V.VendorName,V.VendorName+(CASE WHEN(SELECT COUNT(1)
                                                                                      FROM dbo.Vendor VD WITH(NOLOCK)
                                                                                      WHERE VD.VendorName=V.VendorName AND VD.MasterCompanyId=@MasterCompanyId)>1 THEN ' - '+V.VendorCode ELSE '' END) AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH(NOLOCK) WHERE V.MasterCompanyId=@MasterCompanyId AND V.VendorId IN(SELECT Item FROM dbo.SPLITSTRING(@Idlist,','))
                        END
                        ELSE IF(@TableName='Vendor' AND ISNULL(@IsFromUpload,0)=1)BEGIN
                                SELECT TOP 50 V.VendorId AS Value,V.VendorName,V.VendorName AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH(NOLOCK)
                                WHERE V.MasterCompanyId=@MasterCompanyId AND ISNULL(V.IsActive,1)=1 AND ISNULL(V.IsDeleted,0)=0 AND V.VendorName LIKE '%'+@Parameter3+'%'
                                UNION
                                SELECT V.VendorId AS Value,V.VendorName,V.VendorName AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH(NOLOCK)
                                WHERE V.MasterCompanyId=@MasterCompanyId AND V.VendorId IN(SELECT Item FROM dbo.SPLITSTRING(@Idlist,','))
                        END
                         ELSE BEGIN
                                  SET @Sql=N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)
           SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
                   CAST ( '+      @Parameter2+' AS VARCHAR(MAX)) AS Label,
             MasterCompanyId FROM dbo.['+@TableName+'] WITH(NOLOCK) WHERE MasterCompanyId = '+CAST(@MasterCompanyId AS nvarchar(50))+' AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+@Idlist+''','',''))

            INSERT INTO #TempTable (Value, Label, MasterCompanyId)
            SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
                CAST('+           @Parameter2+' AS VARCHAR(MAX)) AS Label,
       MasterCompanyId FROM dbo.['+@TableName+'] WITH(NOLOCK) WHERE MasterCompanyId = '+CAST(@MasterCompanyId AS nvarchar(50))+' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+@Parameter3+'%'''
                         END
                     END
                     ELSE BEGIN
                         IF(@TableName='InventoryGLSetting')BEGIN
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=1 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                                UNION
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=1 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                ORDER BY StockInventoryName asc
                         END
                         ELSE IF(@TableName='InventoryGLSettingNonStock')BEGIN
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=0 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                                UNION
                                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=0 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                ORDER BY StockInventoryName asc
                         END
                         ELSE BEGIN
                         SET @Sql=N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)
                          SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
        CAST('+          @Parameter2+' AS VARCHAR(MAX)) AS Label,
        MasterCompanyId FROM  dbo.['+@TableName+'] WITH(NOLOCK) WHERE MasterCompanyId = '+CAST(@MasterCompanyId AS nvarchar(50))+' AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+@Idlist+''','',''))

   INSERT INTO #TempTable (Value, Label, MasterCompanyId)
            SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
      CAST('+            @Parameter2+' AS VARCHAR(MAX)) AS Label,
      MasterCompanyId FROM dbo.['+@TableName+'] WITH(NOLOCK) WHERE MasterCompanyId = '+CAST(@MasterCompanyId AS nvarchar(50))+' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+@Parameter3+'%''';
                         END
                     END
            END
        END
        ELSE BEGIN
            IF(@TableName='Employee')BEGIN
                IF(@Parameter4=1)BEGIN
                    SELECT DISTINCT top 20 EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(FirstName LIKE '%'+@Parameter3+'%' OR LastName LIKE '%'+@Parameter3+'%'))
                    UNION
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EmployeeId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
                ELSE BEGIN
                    SELECT DISTINCT top 20 EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(FirstName LIKE '%'+@Parameter3+'%' OR LastName LIKE '%'+@Parameter3+'%')
                    UNION
                    SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
                    FROM dbo.Employee WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EmployeeId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
            END
			ELSE IF(@TableName='EngineRegistryHeader')BEGIN
                IF(@Parameter4=1)BEGIN
                    SELECT DISTINCT top 20 EngineRegistryId AS Value, SerialNum+' '+EngineName+' '+EngineModel AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(SerialNum LIKE '%'+@Parameter3+'%' OR EngineName LIKE '%'+@Parameter3+'%'))
                    UNION
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EngineRegistryId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
                ELSE BEGIN
                    SELECT DISTINCT top 20 EngineRegistryId AS Value, SerialNum+' '+EngineName+' '+EngineModel AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(SerialNum LIKE '%'+@Parameter3+'%' OR EngineName LIKE '%'+@Parameter3+'%')
                    UNION
                    SELECT DISTINCT EngineRegistryId AS Value, SerialNum+' '+EngineName AS Label
                    FROM dbo.EngineRegistryHeader WITH(NOLOCK)
                    WHERE MasterCompanyId=@MasterCompanyId AND EngineRegistryId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                END
            END
			ELSE IF (@TableName='EmpTrainer')
			BEGIN
				SELECT DISTINCT e.EmployeeId AS Value, e.FirstName+' '+e.LastName AS Label
				FROM dbo.Employee e WITH(NOLOCK)
				WHERE e.MasterCompanyId=@MasterCompanyId AND ISNULL(e.IsDeleted,0)=0
				  AND EXISTS (SELECT 1 FROM STRING_SPLIT(e.EmployeeExpIds,',') s WHERE TRY_CAST(s.value AS INT)=@TrainerExpertiseId)
				  AND (
						(@Parameter4=1 AND (e.IsActive=1 AND (e.FirstName LIKE '%'+@Parameter3+'%' OR e.LastName LIKE '%'+@Parameter3+'%')))
					 OR (@Parameter4<>1 AND (e.IsActive=1 AND (e.FirstName LIKE '%'+@Parameter3+'%' OR e.LastName LIKE '%'+@Parameter3+'%')))
					 OR e.EmployeeId IN (SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@Idlist,','))
				  )
				ORDER BY Label;
			 END
			ELSE IF(@TableName='PublicationType')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY Name asc
                     END
                     ELSE
					 BEGIN
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND Description LIKE '%'+@Parameter3+'%'
                         UNION
                         SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
                         FROM dbo.PublicationType P WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY Name asc
                     END
            END
            ELSE IF(@TableName='Task')BEGIN
                     IF(@Parameter4=1)BEGIN
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence , IsTravelerTask, StandardHours, StandardMinute, Descrepancy, Resolution, IsPrintInWO, IsPrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Description LIKE '%'+@Parameter3+'%'))
                         UNION
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence, IsTravelerTask, StandardHours, StandardMinute, Descrepancy, Resolution, IsPrintInWO, IsPrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND TaskId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
                     END
                     ELSE BEGIN
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence , IsTravelerTask, StandardHours, StandardMinute, Descrepancy, Resolution
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND Description LIKE '%'+@Parameter3+'%'
                         UNION
                         SELECT DISTINCT TaskId AS Value, Description AS Label, Sequence , IsTravelerTask, StandardHours, StandardMinute, Descrepancy, Resolution
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND TaskId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
                     END
            END
            ELSE IF(@TableName='ConsigneeLot')BEGIN
                     SELECT DISTINCT TOP 20 LotId AS Value, LotNumber AS Label
                     FROM dbo.LOT WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                     UNION
                     SELECT DISTINCT LotId AS Value, LotNumber AS Label
                     FROM dbo.Lot WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                     ORDER BY LotId DESC
            END
            ELSE IF(@TableName='LotLatest')BEGIN
                     SELECT DISTINCT TOP 20 LotId AS Value, LotNumber AS Label
                     FROM dbo.LOT WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))
                     UNION
                     SELECT DISTINCT LotId AS Value, LotNumber AS Label
                     FROM dbo.Lot WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                     ORDER BY LotId DESC
            END
            ELSE IF(@TableName='ItemMasterNonStock')BEGIN
                     SELECT IM.ItemMasterId as Value, IM.partnumber as PartNumber, (IM.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                               FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                               WHERE IM.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0)=1)>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Non-Stock)') AS Label, IM.MasterCompanyId, IM.ManufacturerName As ManufacturerName
                     FROM dbo.ItemMaster IM
                     WHERE IM.MasterCompanyId=@MasterCompanyId AND ISNULL(IM.IsActive, 1)=1 AND ISNULL(IM.IsDeleted, 0)=0 AND (IM.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                      AND ISNULL(IM.IsNonStock,0) = 1
            END
            ELSE IF(@TableName='InventoryGLSetting')BEGIN
                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=1 AND StockInventoryName LIKE '%'+@Parameter3+'%'
                UNION
                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=1 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                ORDER BY StockInventoryName asc
            END
            ELSE IF(@TableName='InventoryGLSettingNonStock')BEGIN
                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                WHERE MasterCompanyId=@MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=0 AND StockInventoryName LIKE '%'+@Parameter3+'%'
                UNION
                SELECT DISTINCT InventoryGLSettingId AS Value, StockInventoryName AS Label
                FROM dbo.InventoryGLSetting WITH(NOLOCK)
                WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=0 AND InventoryGLSettingId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                ORDER BY StockInventoryName asc
            END
			 ELSE IF(@TableName='BatchDetails')BEGIN
                     SELECT DISTINCT TOP 20 MAX(JournalBatchDetailId) AS Value, JournalTypeNumber AS Label
                     FROM dbo.BatchDetails WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(JournalTypeNumber LIKE '%'+@Parameter3+'%')) GROUP BY JournalTypeNumber
                     UNION
                     SELECT DISTINCT MAX(JournalBatchDetailId) AS Value, JournalTypeNumber AS Label
                     FROM dbo.BatchDetails WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND JournalBatchDetailId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') ) GROUP BY JournalTypeNumber
            END
			ELSE IF(@TableName='Stockline')BEGIN
                     SELECT DISTINCT TOP 20 MAX(StocklineId) AS Value, StockLineNumber AS Label
                     FROM dbo.Stockline WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(StockLineNumber LIKE '%'+@Parameter3+'%')) GROUP BY StockLineNumber
                     UNION
                     SELECT DISTINCT MAX(StocklineId) AS Value, StockLineNumber AS Label
                     FROM dbo.Stockline WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND StocklineId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') ) GROUP BY StockLineNumber
            END
            ELSE IF(@TableName='SalesOrderQuote')BEGIN
                     SELECT DISTINCT TOP 20 SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                     FROM dbo.SalesOrderQuote WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND IsNewVersionCreated = 0 AND(SalesOrderQuoteNumber LIKE '%'+@Parameter3+'%'))
                     UNION
                     SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                     FROM dbo.SalesOrderQuote WITH(NOLOCK)
                     WHERE MasterCompanyId=@MasterCompanyId AND IsNewVersionCreated = 0 AND SalesOrderQuoteId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                     ORDER BY SalesOrderQuoteId DESC
            END
            ELSE BEGIN
                     IF(@Parameter4=1)BEGIN
                         IF(@TableName='ItemMaster' AND ISNULL(@IsFromUpload,0) = 0)BEGIN
                             SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, (im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                           FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                           WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Stock)') AS Label, IM.MasterCompanyId, im.ManufacturerName AS ManufacturerName, im.IsSerialized ,IM.IsOEM
                             FROM dbo.ItemMaster IM
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                              AND ISNULL(IM.IsNonStock,0) = 0
                              UNION
                             SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber, (im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                    FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                    WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Stock)') AS Label, IM.MasterCompanyId, im.ManufacturerName AS ManufacturerName, im.IsSerialized ,IM.IsOEM
                             FROM dbo.ItemMaster IM
                             WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                          AND ISNULL(IM.IsNonStock,0) = 0
                              END
						 ELSE IF(@TableName='ItemMaster' AND ISNULL(@IsFromUpload,0) = 1)
							BEGIN
								SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, im.partnumber AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
								 FROM dbo.ItemMaster IM
								 WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
								  AND ISNULL(IM.IsNonStock,0) = 0
								  UNION
								 SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber, im.partnumber AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName, im.IsSerialized ,IM.IsOEM
								 FROM dbo.ItemMaster IM
								 WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
							 AND ISNULL(IM.IsNonStock,0) = 0
								  END
                         ELSE IF(@TableName='ItemMasterALL')BEGIN
                                  SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,IM.PartDescription AS PartDescription, im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                         FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                         WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END) AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE Im.MasterCompanyId=@MasterCompanyId AND ISNULL(IsActive, 1)=1 AND ISNULL(IsDeleted, 0)=0 AND (Im.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', '')+'%')
                                   AND ISNULL(IM.IsNonStock,0) = 0
                                   UNION
                                  SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,IM.PartDescription AS PartDescription, im.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                         FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                         WHERE im.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 )>1 then ' - '+IM.ManufacturerName ELSE '' END) AS Label, IM.MasterCompanyId, im.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE Im.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                          AND ISNULL(IM.IsNonStock,0) = 0
                                   END
                         ELSE IF(@TableName='ItemMasterNonStock')BEGIN
                                  SELECT TOP 50 IM.ItemMasterId as Value, IM.partnumber as PartNumber, (IM.partnumber+(CASE WHEN(SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))
                                                                                                                                   FROM [dbo].[ItemMaster] SD WITH(NOLOCK)
                                                                                                                                   WHERE IM.partnumber=SD.partnumber AND SD.MasterCompanyId=@MasterCompanyId AND ISNULL(SD.IsNonStock,0)=1)>1 then ' - '+IM.ManufacturerName ELSE '' END)+' (Non-Stock)') AS Label, IM.MasterCompanyId, IM.ManufacturerName As ManufacturerName
                                  FROM dbo.ItemMaster IM
                                  WHERE IM.MasterCompanyId=@MasterCompanyId AND ISNULL(IM.IsActive, 1)=1 AND ISNULL(IM.IsDeleted, 0)=0 AND (IM.PartNumber like '%'+@Parameter3+'%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') like '%'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Parameter3, '-', ''), '/', ''), '_', ''), '\', ''), '\', '')+'%')
                                   AND ISNULL(IM.IsNonStock,0) = 1
                         END
                         ELSE IF(@TableName='InventoryGLSetting')BEGIN
                            SELECT TOP 50 InventoryGLSettingId AS Value, StockInventoryName AS Label
                            FROM dbo.InventoryGLSetting WITH(NOLOCK)
                            WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=1 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                            UNION
                            SELECT InventoryGLSettingId AS Value, StockInventoryName AS Label
                            FROM dbo.InventoryGLSetting WITH(NOLOCK)
                            WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=1 AND InventoryGLSettingId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                        END
                        ELSE IF(@TableName='InventoryGLSettingNonStock')BEGIN
                            SELECT TOP 50 InventoryGLSettingId AS Value, StockInventoryName AS Label
                            FROM dbo.InventoryGLSetting WITH(NOLOCK)
                            WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsStock,1)=0 AND(StockInventoryName LIKE '%'+@Parameter3+'%'))
                            UNION
                            SELECT InventoryGLSettingId AS Value, StockInventoryName AS Label
                            FROM dbo.InventoryGLSetting WITH(NOLOCK)
                            WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsStock,1)=0 AND InventoryGLSettingId in(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                        END
                         ELSE IF(@TableName='ConsigneeLot')BEGIN
                                  SELECT TOP 20 LotId AS Value, LotNumber AS Label
                                  FROM dbo.LOT WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                                  UNION
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.Lot WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )AND LotId NOT IN(SELECT ISNULL(LotId, 0)FROM LotConsignment)
                                  ORDER BY LotId DESC
                         END
                         ELSE IF(@TableName='LotLatest')BEGIN
                                  SELECT TOP 20 LotId AS Value, LotNumber AS Label
                                  FROM dbo.LOT WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(LotNumber LIKE '%'+@Parameter3+'%'))
                                  UNION
                                  SELECT DISTINCT LotId AS Value, LotNumber AS Label
                                  FROM dbo.Lot WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND LotId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                  ORDER BY LotId DESC
                         END
						  ELSE IF(@TableName='PublicationType')BEGIN
                                  SELECT TOP 20 PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
										FROM dbo.PublicationType P WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND([Name] LIKE '%'+@Parameter3+'%'))
                                  UNION
                                  SELECT DISTINCT PublicationTypeId as Value, [Name] as Label, (SELECT TOP 1 EmailBody FROM DBO.PublicationTemplate PT WITH(NOLOCK) WHERE PT.PublicationTypeId = P.PublicationTypeId AND Pt.MasterCompanyId = P.MasterCompanyId ) as PublicationTemplate
									FROM dbo.PublicationType P WITH(NOLOCK)
                                  WHERE MasterCompanyId=@MasterCompanyId AND PublicationTypeId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                  ORDER BY PublicationTypeId DESC
                         END
						 ELSE IF(@TableName = 'VendorOrderType') BEGIN
							  SELECT VT.VendorOrderTypeId as Value, VT.OrderTypeName as Label
								 FROM dbo.VendorOrderType VT WITH(NOLOCK)
							  WHERE VT.IsActive = 1 AND VT.IsDeleted = 0;
						 END
						 ELSE IF(@TableName = 'VendorAuditType') BEGIN
							  SELECT VAT.VendorAuditTypeId as Value, VAT.VendorAuditType as Label
								 FROM dbo.VendorAuditType VAT WITH(NOLOCK)
							  WHERE VAT.MasterCompanyId=@MasterCompanyId AND VAT.IsActive = 1 AND VAT.IsDeleted = 0;
						 END
                         ELSE IF(@TableName='SalesOrderQuote')BEGIN
                                 SELECT DISTINCT TOP 20 SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND IsNewVersionCreated = 0 AND(SalesOrderQuoteNumber LIKE '%'+@Parameter3+'%'))
                                 UNION
                                 SELECT DISTINCT SalesOrderQuoteId AS Value, SalesOrderQuoteNumber AS Label
                                 FROM dbo.SalesOrderQuote WITH(NOLOCK)
                                 WHERE MasterCompanyId=@MasterCompanyId AND IsNewVersionCreated = 0 AND SalesOrderQuoteId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                                 ORDER BY SalesOrderQuoteId DESC
                        END
                        ELSE IF(@TableName='Vendor' AND ISNULL(@IsFromUpload,0) = 0)BEGIN
                                SELECT TOP 50 V.VendorId AS Value,V.VendorName,V.VendorName +(CASE WHEN (SELECT COUNT(1)
                                                                                                            FROM dbo.Vendor VD WITH (NOLOCK)
                                                                                                            WHERE VD.VendorName = V.VendorName AND VD.MasterCompanyId = @MasterCompanyId AND ISNULL(VD.IsDeleted, 0) = 0 ) > 1 THEN ' - ' + ISNULL(V.VendorCode, '') ELSE ''END ) AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH (NOLOCK)
                                WHERE V.MasterCompanyId = @MasterCompanyId AND ISNULL(V.IsActive, 1) = 1 AND ISNULL(V.IsDeleted, 0) = 0 AND V.VendorName LIKE '%' + @Parameter3 + '%'
                                UNION
                                SELECT V.VendorId AS Value,V.VendorName,V.VendorName +(CASE WHEN (SELECT COUNT(1)
                                                                                                    FROM dbo.Vendor VD WITH (NOLOCK)
                                                                                                    WHERE VD.VendorName = V.VendorName AND VD.MasterCompanyId = @MasterCompanyId AND ISNULL(VD.IsDeleted, 0) = 0) > 1THEN ' - ' + ISNULL(V.VendorCode, '') ELSE '' END) AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH (NOLOCK)
                                WHERE V.MasterCompanyId = @MasterCompanyId AND V.VendorId IN (SELECT Item FROM dbo.SPLITSTRING(@Idlist, ','))
                        END
                        ELSE IF (@TableName = 'Vendor' AND ISNULL(@IsFromUpload, 0) = 1)BEGIN
                                SELECT TOP 50 V.VendorId AS Value,V.VendorName,V.VendorName AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH (NOLOCK)
                                WHERE V.MasterCompanyId = @MasterCompanyId AND ISNULL(V.IsActive, 1) = 1 AND ISNULL(V.IsDeleted, 0) = 0 AND V.VendorName LIKE '%' + @Parameter3 + '%'
                                UNION
                                SELECT V.VendorId AS Value,V.VendorName,V.VendorName AS Label,V.MasterCompanyId,V.VendorCode
                                FROM dbo.Vendor V WITH (NOLOCK)
                                WHERE V.MasterCompanyId = @MasterCompanyId AND V.VendorId IN (SELECT Item FROM dbo.SPLITSTRING(@Idlist, ','))
                        END
                         ELSE BEGIN
                                  SET @Sql=N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)
             SELECT DISTINCT TOP '+@Count+' CAST ( '+@Parameter1+' AS BIGINT) As Value,
               CAST ( '+          @Parameter2+' AS VARCHAR(MAX)) AS Label,
               MasterCompanyId FROM  dbo.['+@TableName+'] WHERE MasterCompanyId =  '+CAST(@MasterCompanyId AS nvarchar(50))+'  AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+@Idlist+''','',''))

    INSERT INTO #TempTable (Value, Label, MasterCompanyId)
        SELECT DISTINCT TOP '+    @Count+' CAST ( '+@Parameter1+' AS BIGINT) As Value,
         CAST('+                  @Parameter2+' AS VARCHAR(MAX)) AS Label,
         MasterCompanyId FROM  dbo.['+@TableName+'] WHERE MasterCompanyId =  '+CAST(@MasterCompanyId AS nvarchar(50))+'  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+@Parameter3+'%'''
                         END
                     END
                     ELSE BEGIN
                         SET @Sql=N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)
                          SELECT DISTINCT TOP '+@Count+' CAST ( '+@Parameter1+' AS BIGINT) As Value,
        CAST ( '+        @Parameter2+' AS VARCHAR(MAX)) AS Label,
        MasterCompanyId FROM  dbo.['+@TableName+'] WHERE MasterCompanyId =  '+CAST(@MasterCompanyId AS nvarchar(50))+'  AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+@Idlist+''','',''))

          INSERT INTO #TempTable (Value, Label, MasterCompanyId)
            SELECT DISTINCT TOP '+@Count+' CAST ( '+@Parameter1+' AS BIGINT) As Value,
      CAST('+            @Parameter2+' AS VARCHAR(MAX)) AS Label,
      MasterCompanyId FROM  dbo.['+@TableName+'] WHERE MasterCompanyId =  '+CAST(@MasterCompanyId AS nvarchar(50))+'  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+@Parameter3+'%''';
                     END
            END
        END
        PRINT @Sql
        EXEC sp_executesql @Sql;
        SELECT DISTINCT *
        FROM #TempTable
        WHERE MasterCompanyId=@MasterCompanyId
        ORDER BY Label
        DROP Table #TempTable
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) =db_name(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE-----------
            @AdhocComments VARCHAR(150) ='AutoCompleteDropdowns', @ProcedureParameters VARCHAR(3000) =
			'@Parameter1 = '''+CAST(ISNULL(@TableName, '') as varchar(100))+
			'@Parameter2 = '''+CAST(ISNULL(@Parameter1, '') as varchar(100))+
			'@Parameter3 = '''+CAST(ISNULL(@Parameter2, '') as varchar(100))+
			'@Parameter4 = '''+CAST(ISNULL(@Parameter3, '') as varchar(100))+
			'@Parameter5 = '''+CAST(ISNULL(@Parameter4, '') as varchar(100))+
			'@Parameter6 = '''+CAST(ISNULL(@Count, '') as varchar(100))+
			'@Parameter7 = '''+CAST(ISNULL(@Idlist, '') as varchar(100))+
			'@Parameter8 = '''+CAST(ISNULL(@MasterCompanyId, '') as varchar(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException @DatabaseName=@DatabaseName, @AdhocComments=@AdhocComments, @ProcedureParameters=@ProcedureParameters, @ApplicationName=@ApplicationName, @ErrorLogID=@ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END