/*************************************************************           
 ** File:   [USP_WorkOrderReleaseFromListData_ByWOId]           
 ** Author:   Devendra Shekh
 ** Description: this SP is used to get the Work Order Release form Details by Work Order Id
 ** Purpose:         
 ** Date:    10-June-2025
 ** PARAMETERS:                   
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    10-June-2025		Devendra Shekh		Created
    2    25-June-2025		Devendra Shekh		Remarks Breaks Issue Resolved
	3    10/10/2025         Moin Bloch          Updated For Get VersionNo & IsVersionIncrease Flag
	4    14/10/2025         Moin Bloch          Updated For Get VersionNo
	5    24/06/2026         Amit Ghediya         Updated For get LogBook Label data [PN-16471]
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

 EXECUTE [USP_WorkOrderReleaseFromListData_ByWOId] 8992,2
**************************************************************/ 

CREATE   Procedure [dbo].[USP_WorkOrderReleaseFromListData_ByWOId]
@WorkorderId BIGINT,
@EmployeeId BIGINT = 0,
@IsFromLogBook BIT = 0
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

	DECLARE @MSModuleId INT;
	DECLARE @WorkOrderSettlementId BIGINT;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SET @MSModuleId = 0; -- For WO PART NUMBER

	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

	IF OBJECT_ID('tempdb..#tmpWork_ReleaseForm') IS NOT NULL
		DROP TABLE #tmpWork_ReleaseForm

	CREATE TABLE #tmpWork_ReleaseForm (
		[ReleaseFromId] [bigint] NULL,
		[WorkorderId] [bigint] NULL,
		[workOrderPartNoId] [bigint] NULL,
		[Country] [varchar](256) NULL,
		[OrganizationName] [varchar](max) NULL,
		[InvoiceNo] [varchar](256) NULL,
		[ItemName] [varchar](256) NULL,
		[PartNumber] [varchar](256) NULL,----
		[Description] [varchar](MAX) NULL,---
		[Reference] [varchar](256) NULL,
		[Quantity] [int] NULL,
		[Batchnumber] [varchar](256) NULL,
		[status] [varchar](20) NULL,
		[Remarks] [varchar](max) NULL,
		[Certifies] [varchar](256) NULL,
		[approved] [bit] NULL,
		[Nonapproved] [bit] NULL,
		[AuthorisedSign] [varchar](256) NULL,
		[AuthorizationNo] [varchar](256) NULL,
		[PrintedName] [varchar](256) NULL,
		[Date] [datetime] NULL,
		[AuthorisedSign2] [varchar](256) NULL,
		[ApprovalCertificate] [varchar](256) NULL,
		[PrintedName2] [varchar](256) NULL,
		[Date2] [datetime] NULL,
		[CFR] [bit] NULL,
		[Otherregulation] [bit] NULL,
		[MasterCompanyId] [int] NULL,
		[CreatedBy] [varchar](256) NULL,
		[UpdatedBy] [varchar](256) NULL,
		[CreatedDate] [datetime2](7) NULL,
		[UpdatedDate] [datetime2](7) NULL,
		[IsActive] [bit] NULL,
		[IsDeleted] [bit] NULL,
		[trackingNo] [varchar](20) NULL,
		[OrganizationAddress] [varchar](500) NULL,
		[is8130from] [bit] NULL,
		[IsClosed] [bit] NULL,
		[ReceivedDate] [datetime2] NULL,
		[islocked] [bit] NULL,
		[IsEASALicense] [bit] NULL,
		[FormType] [varchar](100) NULL,
		[ManagementStructureId] [bigint] NULL,
		[EmployeeId] [bigint] NULL,
		[FormTypeId] [int] NULL,
		[WOFormType] [varchar](50) NULL,
		[Is813013aeOr14ae] [bit] NULL,
		[VersionNo] [varchar](50) NULL,
		[IsVersionIncrease] [bit] NULL,
		[IsAircraftLogBook] [bit] NULL
	);

	SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDERMPN';
				
	SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE UPPER([WorkOrderSettlementName]) = UPPER('FINAL COND/CERT');

		IF(ISNULL(@IsFromLogBook,0) = 0)
		BEGIN
			;WITH ReleaseFormResult AS (
			SELECT 
				wro.[ReleaseFromId]
				,wro.[Quantity]
				,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS [PartNumber]
				,CASE WHEN ISNULL(wop.RevisedSerialNumber , '') != '' THEN UPPER(wop.RevisedSerialNumber) 
						ELSE CASE WHEN ISNULL(wro.[Batchnumber], '') != '' THEN UPPER(wro.[Batchnumber])
								ELSE CASE WHEN ISNULL(sl.SerialNumber,'') != '' THEN UPPER(sl.SerialNumber) ELSE '' END 
						END
				END AS Batchnumber
				,CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN C.Memo ELSE wosc.conditionName END AS [status]
				,wro.[FormTypeId]
				,ISNULL(wro.[Reference], '') AS [Reference]
				,CASE WHEN ISNULL(wro.Remarks, '') = '' THEN '' ELSE LTRIM(RTRIM(
																		TRY_CAST(REPLACE(wro.Remarks, '&nbsp;', ' ') AS XML).value('.', 'NVARCHAR(MAX)')
																	)) END AS [Remarks]
				,ISNULL(wro.[VersionNo],'')	[VersionNo]	
			FROM [dbo].[Work_ReleaseFrom_8130] wro WITH(NOLOCK)
					LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wro.workOrderPartNoId = wop.Id
					LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0  
					LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					 AND ISNULL(im.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
					 AND ISNULL(ims.IsNonStock,0) = 0
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = @WorkOrderSettlementId
					LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
					LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
			WHERE wro.[WorkOrderId] = @WorkorderId AND ISNULL(wro.[IsVersionIncrease],0) = 0
			)

		
			INSERT INTO #tmpWork_ReleaseForm ([ReleaseFromId], [Quantity], [PartNumber], [Batchnumber], [status], [FormTypeId], [Reference], [Remarks],[VersionNo])
			SELECT MAX([ReleaseFromId]), SUM(ISNULL([Quantity], 0)), [PartNumber], [Batchnumber], [status], [FormTypeId], [Reference], [Remarks],[VersionNo]
			FROM ReleaseFormResult
			GROUP BY  [PartNumber], [Batchnumber], [status], [FormTypeId], [Reference], [Remarks], [VersionNo]

			UPDATE TMP
			SET
				TMP.WorkorderId           = wro.WorkorderId,
				TMP.workOrderPartNoId     = wro.workOrderPartNoId,
				TMP.Country               = wro.Country,
				TMP.OrganizationName      = wro.OrganizationName,
				TMP.InvoiceNo             = wro.InvoiceNo,
				TMP.ItemName              = wro.ItemName,
				TMP.[Description]         = CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END,
				--TMP.Reference             = wro.Reference,
				TMP.Remarks               = wro.Remarks,
				TMP.Certifies             = wro.Certifies,
				TMP.Approved              = wro.Approved,
				TMP.Nonapproved           = wro.Nonapproved,
				TMP.AuthorisedSign        = wro.AuthorisedSign,
				TMP.AuthorizationNo       = UPPER(CASE WHEN wro.is8130from = 1 THEN le.FAALicense ELSE le.EASALicense END),
				TMP.PrintedName           = wro.PrintedName,
				TMP.[Date]                = wro.Date,
				TMP.AuthorisedSign2       = wro.AuthorisedSign2,
				TMP.ApprovalCertificate   = UPPER(CASE WHEN wro.is8130from = 1 THEN le.FAALicense ELSE le.EASALicense END),
				TMP.PrintedName2          = wro.PrintedName2,
				TMP.Date2                 = wro.Date2,
				TMP.CFR                   = wro.CFR,
				TMP.Otherregulation       = wro.Otherregulation,
				TMP.MasterCompanyId       = wro.MasterCompanyId,
				TMP.CreatedBy             = wro.CreatedBy,
				TMP.UpdatedBy             = wro.UpdatedBy,
				TMP.CreatedDate           = CASE 
												WHEN CAST(wro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL 
												ELSE CAST(DBO.ConvertUTCtoLocal(wro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE) 
											END,
				TMP.UpdatedDate           = CASE 
												WHEN CAST(wro.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL 
												ELSE CAST(DBO.ConvertUTCtoLocal(wro.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE) 
											END,
				TMP.IsActive              = wro.IsActive,
				TMP.IsDeleted             = wro.IsDeleted,
				TMP.trackingNo            = wro.trackingNo,
				TMP.OrganizationAddress   = wro.OrganizationAddress,
				TMP.is8130from            = wro.is8130from,
				TMP.IsClosed              = wro.IsClosed,
				TMP.ReceivedDate          = wop.ReceivedDate,
				TMP.islocked              = wro.islocked,
				TMP.IsEASALicense         = wro.IsEASALicense,
				TMP.FormType              = CASE WHEN wro.is8130from = 1 THEN '8130 Certificate' ELSE '9130 Form' END,
				TMP.ManagementStructureId = wop.ManagementStructureId,
				TMP.EmployeeId            = wro.EmployeeId,
				TMP.WOFormType            = CASE 
												WHEN wro.FormTypeId = 1 THEN '8130 ONLY'
												WHEN wro.FormTypeId = 2 THEN 'EASA'
												WHEN wro.FormTypeId = 3 THEN 'UK-CAA'
												ELSE '' 
											END,
				TMP.Is813013aeOr14ae      = wro.Is813013aeOr14ae,
				--TMP.[VersionNo]           = wro.[VersionNo],
				TMP.[IsVersionIncrease]   = ISNULL(wro.[IsVersionIncrease],0),
				TMP.[IsAircraftLogBook]   = 0
			FROM #tmpWork_ReleaseForm TMP
			JOIN [Work_ReleaseFrom_8130] wro ON TMP.ReleaseFromId = wro.ReleaseFromId AND ISNULL(wro.[IsVersionIncrease],0) = 0
			LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wro.workOrderPartNoId = wop.Id
			LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0  
			LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
			 AND ISNULL(im.IsNonStock,0) = 0
			 LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
			 AND ISNULL(ims.IsNonStock,0) = 0
			  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = @WorkOrderSettlementId
			LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
			LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
			LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
			LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId;
		END

		--LogBook
		IF(ISNULL(@IsFromLogBook,0) = 1)
		BEGIN
			INSERT INTO #tmpWork_ReleaseForm
				([ReleaseFromId], [WorkorderId], [workOrderPartNoId], [Country], [OrganizationName], [InvoiceNo], [ItemName],
				 [PartNumber], [Description], [Reference], [Quantity], [Batchnumber], [status], [Remarks], [Certifies],
				 [approved], [Nonapproved], [AuthorisedSign], [AuthorizationNo], [PrintedName], [Date], [AuthorisedSign2],
				 [ApprovalCertificate], [PrintedName2], [Date2], [CFR], [Otherregulation], [MasterCompanyId], [CreatedBy],
				 [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [trackingNo], [OrganizationAddress],
				 [is8130from], [IsClosed], [ReceivedDate], [islocked], [IsEASALicense], [FormType], [ManagementStructureId],
				 [EmployeeId], [FormTypeId], [WOFormType], [Is813013aeOr14ae], [VersionNo], [IsVersionIncrease], [IsAircraftLogBook])
			SELECT
				 lcf.[LogbookCertificateFromId]                                  -- ReleaseFromId
				,lcf.[WorkorderId]
				,lcf.[workOrderPartNoId]
				,lcf.[Country]
				,lcf.[OrganizationName]
				,lcf.[InvoiceNo]
				,lcf.[ItemName]
				,UPPER(lcf.[PartNumber])
				,UPPER(lcf.[Description])
				,lcf.[Reference]
				,1                                                               -- Quantity (no rollup on logbook)
				,NULL                                                            -- Batchnumber
				,lcf.[status]
				,CASE WHEN ISNULL(lcf.Remarks, '') = '' THEN '' ELSE LTRIM(RTRIM(
						TRY_CAST(REPLACE(lcf.Remarks, '&nbsp;', ' ') AS XML).value('.', 'NVARCHAR(MAX)')
					)) END
				,lcf.[Certifies]
				,NULL                                                            -- approved
				,NULL                                                            -- Nonapproved
				,lcf.[AuthorisedSign]
				,UPPER(lcf.[AuthorizationNo])
				,lcf.[PrintedName]
				,lcf.[Date]
				,lcf.[AuthorisedSign2]
				,UPPER(lcf.[ApprovalCertificate])
				,lcf.[PrintedName2]
				,lcf.[Date2]
				,NULL                                                            -- CFR
				,NULL                                                            -- Otherregulation
				,lcf.[MasterCompanyId]
				,lcf.[CreatedBy]
				,lcf.[UpdatedBy]
				,CASE WHEN CAST(lcf.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL
					  ELSE CAST(DBO.ConvertUTCtoLocal(lcf.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE) END
				,CASE WHEN CAST(lcf.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL
					  ELSE CAST(DBO.ConvertUTCtoLocal(lcf.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE) END
				,lcf.[IsActive]
				,lcf.[IsDeleted]
				,NULL                                                            -- trackingNo
				,lcf.[OrganizationAddress]
				,NULL                                                            -- is8130from (logbook is neither)
				,NULL                                                            -- IsClosed
				,wop.ReceivedDate                                                 -- ReceivedDate
				,NULL                                                            -- islocked
				,NULL                                                            -- IsEASALicense
				,'Logbook Certificate'                                           -- FormType
				,wop.ManagementStructureId                                                            -- ManagementStructureId
				,lcf.[EmployeeId]
				,CASE WHEN ISNULL(lcf.IsAircraftLogBook,0) > 0 THEN 4 ELSE 5 END 
				,CASE WHEN ISNULL(lcf.IsAircraftLogBook,0) > 0 THEN 'Aircraft Logbook Label' ELSE 'Engine Logbook Label' END                                                       -- WOFormType
				,NULL                                                            -- Is813013aeOr14ae
				,NULL                                                            -- VersionNo
				,NULL                                                            -- IsVersionIncrease
				,lcf.IsAircraftLogBook
			FROM [dbo].[Work_LogbookCertificateFrom] lcf WITH(NOLOCK)
			LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON lcf.workOrderPartNoId = wop.Id
			WHERE lcf.[WorkorderId] = @WorkorderId;
		END

		-- Final Result Select
		SELECT	[ReleaseFromId], [WorkorderId], [workOrderPartNoId], [Country], [OrganizationName], [InvoiceNo], [ItemName], [PartNumber], [Description], [Reference], [Quantity], [Batchnumber], [status], [Remarks],
				[Certifies], [approved], [Nonapproved], [AuthorisedSign], [AuthorizationNo], [PrintedName], [Date], [AuthorisedSign2], [ApprovalCertificate], [PrintedName2], [Date2], [CFR], [Otherregulation],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [trackingNo], [OrganizationAddress], [is8130from], [IsClosed], [ReceivedDate], [islocked], [IsEASALicense],
				[FormType], [ManagementStructureId], [EmployeeId], [FormTypeId], [WOFormType], [Is813013aeOr14ae], [VersionNo], [IsVersionIncrease], [IsAircraftLogBook]
		FROM #tmpWork_ReleaseForm
				 
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_WorkOrderReleaseFromListData_ByWOId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkorderId AS VARCHAR(10)) ,'') + ''''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END