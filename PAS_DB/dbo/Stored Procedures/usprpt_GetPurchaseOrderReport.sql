
/*************************************************************           
 ** File:   [usprpt_GetPurchaseOrderReport]           
 ** Author:   HEMANT 
 ** Description: Get Data for PurchaseOrderReport  
 ** Purpose:         
 ** Date:   02-MAY-2022       
          
 ** PARAMETERS:          
   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
	1	 02-MAY-2022   Hemant		Added Updated for Upper Case
     
EXECUTE   [dbo].[usprpt_GetPurchaseOrderReport] '','','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetPurchaseOrderReport] 
@PageNumber INT = 1,
@PageSize INT = NULL,
@mastercompanyid INT,
@xmlFilter XML
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      DECLARE 
		@vendorname VARCHAR(40) = NULL,
		@status VARCHAR(40) = NULL,
		@Fromdate DATETIME,
		@Todate DATETIME,
		@tagtype VARCHAR(50) = NULL,
		@level1 VARCHAR(MAX) = NULL,
		@level2 VARCHAR(MAX) = NULL,
		@level3 VARCHAR(MAX) = NULL,
		@level4 VARCHAR(MAX) = NULL,
		@Level5 VARCHAR(MAX) = NULL,
		@Level6 VARCHAR(MAX) = NULL,
		@Level7 VARCHAR(MAX) = NULL,
		@Level8 VARCHAR(MAX) = NULL,
		@Level9 VARCHAR(MAX) = NULL,
		@Level10 VARCHAR(MAX) = NULL,
		@IsDownload BIT = NULL

		DECLARE @ModuleID INT = 5; -- PO PART MS Module ID
		SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

		SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,

			@Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,

			@tagtype=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype END,

			@vendorname=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor Name (Optional)' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @vendorname END,

			@status=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Status' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @status END,

			@level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,

			@level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,

			@level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,

			@level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,

			@level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,

			@level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,

			@level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,

			@level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,

			@level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,

			@level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end

		  FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

		  IF ISNULL(@PageSize,0)=0
			BEGIN 
					SELECT @PageSize=COUNT(*)
					FROM dbo.PurchaseOrder PO WITH (NOLOCK)
						INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
						INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
						LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
					WHERE PO.StatusId IN (SELECT value FROM String_split(@status, ','))
					  AND CAST(PO.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  					  
					  AND PO.VendorId=ISNULL(@vendorname,PO.VendorId) 
					  AND PO.mastercompanyid = @mastercompanyid
					  AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))
					  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
					  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
					  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
					  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
					  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
					  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
					  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
					  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
					  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
					  AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			END

			SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
			SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
			 
			  SELECT COUNT(1) OVER () AS TotalRecordsCount,				
				UPPER(PO.PurchaseOrderNumber) 'ponum',
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PO.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PO.OpenDate, 107) END 'podate', 
				UPPER(POP.partnumber) 'pn',
				UPPER(POP.PartDescription) 'pndescription',
				UPPER(POP.itemtype) 'itemtype',
				UPPER(POP.stocktype) 'stocktype',
				UPPER(PO.status) 'status',
				DATEDIFF(DAY, PO.OpenDate, GETDATE()) 'poage',
				UPPER(PO.VendorName) 'vendorname',
				UPPER(PO.VendorCode) 'vendorcode',
				UPPER(POP.unitofmeasure) 'uom',
				UPPER(PO.Approvedby) 'Approver',
				UPPER(PO.Requisitioner) 'requisitioner',
				UPPER(POP.QuantityOrdered) 'qty',
				FORMAT(POP.UnitCost , 'N', 'en-us') 'unitcost',
				UPPER(POP.functionalcurrency) 'curr',
				--UPPER(pop.ExtendedCost) 'extamt',	
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(POP.ExtendedCost , 'N', 'en-us') ELSE CAST('&nbsp;' + FORMAT(POP.ExtendedCost , 'N', 'en-us') AS VARCHAR(20)) END 'extamt',
				--CAST('&nbsp;' + FORMAT(POP.ExtendedCost , 'N', 'en-us') AS VARCHAR(20)) 'extamt',
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(POP.NeedByDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), POP.NeedByDate, 107) END 'needby',
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(POP.EstDeliveryDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), POP.EstDeliveryDate, 107) END 'prmsddate',
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(POP.EstDeliveryDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), POP.EstDeliveryDate, 107) END 'nextdeldate',
				UPPER(MSD.Level1Name) AS level1,  
				UPPER(MSD.Level2Name) AS level2, 
				UPPER(MSD.Level3Name) AS level3, 
				UPPER(MSD.Level4Name) AS level4, 
				UPPER(MSD.Level5Name) AS level5, 
				UPPER(MSD.Level6Name) AS level6, 
				UPPER(MSD.Level7Name) AS level7, 
				UPPER(MSD.Level8Name) AS level8, 
				UPPER(MSD.Level9Name) AS level9, 
				UPPER(MSD.Level10Name) AS level10 
			FROM dbo.PurchaseOrder PO WITH (NOLOCK)
				INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
				LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			WHERE PO.StatusId IN (SELECT value FROM String_split(@status, ','))
				AND CAST(PO.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
				AND PO.VendorId=ISNULL(@vendorname,PO.VendorId) 
				AND PO.mastercompanyid = @mastercompanyid
				AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))
				AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			ORDER BY POP.partnumber
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usprpt_GetPurchaseOrderReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@status, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter9 = ''' + CAST(ISNULL(@vendorname, '') AS varchar),
            @ApplicationName varchar(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END