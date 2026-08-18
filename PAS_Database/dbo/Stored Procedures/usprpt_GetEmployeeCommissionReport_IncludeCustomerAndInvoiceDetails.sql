/*************************************************************               
 ** File:  [usprpt_GetEmployeeCommissionReport_IncludeCustomerAndInvoiceDetails]      
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to Employee Commission DATA Including Customer & Invoice Details.    
 ** Purpose:             
 ** Date:   18-SEPT-2025          
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date			Author				Change Description                
 ** --   --------		-------				--------------------------------              
	1    13-JAN-2025    Vishal Suthar		Fixed an issue with doubling the amount so added DISTINCT to fix it
    2    18-SEP-2025	Vishal Suthar		Created
	3	 10-OCT-2025	Vishal Suthar		PN-14385 Modifled to include Enhancement to Commission Report Calculation using Employee Default
    4    16-OCT-2025    RAJESH GAMI			handle Null value
	5    09/July/2026    RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
************************************************************************/ 
CREATE PROCEDURE [dbo].[usprpt_GetEmployeeCommissionReport_IncludeCustomerAndInvoiceDetails]
	@PageNumber int = 1,  
	@PageSize int = NULL,  
	@mastercompanyid int,  
	@xmlFilter XML  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
	DECLARE @Fromdate DATETIME;
	DECLARE @Todate DATETIME;
	DECLARE 
	@level1 VARCHAR(MAX) = NULL,  
	@level2 VARCHAR(MAX) = NULL,  
	@level3 VARCHAR(MAX) = NULL,  
	@level4 VARCHAR(MAX) = NULL,  
	@Level5 VARCHAR(MAX) = NULL,  
	@Level6 VARCHAR(MAX) = NULL,  
	@Level7 VARCHAR(MAX) = NULL,  
	@Level8 VARCHAR(MAX) = NULL,  
	@Level9 VARCHAR(MAX) = NULL,  
	@Level10 VARCHAR(MAX) = NULL ,
	@Employee VARCHAR(100) = NULL,
	@Customer VARCHAR(100) = NULL,
	@IncludeCRnRET BIT = NULL;
	
	DECLARE @SOMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'SalesOrder');
	DECLARE @WOMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'WorkOrderMPN');
	DECLARE @SalesOrderModuleId INT = (SELECT ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder');
	DECLARE @WorkOrderModuleId INT = (SELECT ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder');

	BEGIN TRY  
      
	SELECT   
		@Fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Fromdate end,  
		@Todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Todate end,
		@level1=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level1 end,  
		@level2=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level2 end,  
		@level3=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level3 end,  
		@level4=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level4 end,  
		@level5=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level5 end,  
		@level6=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level6 end,  
		@level7=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level7 end,  
		@level8=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level8 end,  
		@level9=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level9 end,  
		@level10=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end,
		@Employee=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Employee Name' 
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Employee END,
		@Customer=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer Name' 
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Customer END,
		@IncludeCRnRET=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Includes credits and returns' 
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @IncludeCRnRET END
	FROM  
		@xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)
  
	   ;WITH InvoicesSOWO AS (
			SELECT DISTINCT 
				BI.BillingInvoicingId,
				BI.ReferenceId AS ReferenceId,
				SOBII.SubReferenceId AS SubReferenceId,
				BI.ModuleId,
				BI.CustomerId,
				BI.InvoiceNo DocNum,
				CASE BI.ModuleId
					WHEN @WorkOrderModuleId THEN 1
					WHEN @SalesOrderModuleId THEN 2
					ELSE 3
				END AS ActivityTypeId,
				CASE WHEN @IncludeCRnRET = 1 
				 THEN ((ISNULL(SOBII.GrandTotal, 0) - (ISNULL(SOBII.SalesTax, 0) + ISNULL(SOBII.OtherTax, 0))) + ISNULL(CM.Amount, 0))
				 ELSE (ISNULL(SOBII.GrandTotal, 0) - (ISNULL(SOBII.SalesTax, 0) + ISNULL(SOBII.OtherTax, 0))) END GrandTotal,
				CASE WHEN @IncludeCRnRET = 1 
				 THEN (((ISNULL(SOBII.GrandTotal, 0) - (ISNULL(SOBII.SalesTax, 0) + ISNULL(SOBII.OtherTax, 0))) + ISNULL(CM.Amount, 0)) - (ISNULL(Stk.UnitCost, 0) * ISNULL(SOBII.QtyBilled, 0)))
				 ELSE ((ISNULL(SOBII.GrandTotal, 0) - (ISNULL(SOBII.SalesTax, 0) + ISNULL(SOBII.OtherTax, 0))) - (ISNULL(Stk.UnitCost, 0) * ISNULL(SOBII.QtyBilled, 0))) END PartCost,
				CAST(BI.InvoiceDate AS DATE) AS InvoiceDate
			FROM dbo.BillingInvoicing BI WITH (NOLOCK)
			INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON BI.BillingInvoicingId = SOBII.BillingInvoicingId 
					AND ISNULL(SOBII.IsVersionIncrease, 0) = 0 
					AND ISNULL(SOBII.IsPerformaInvoice, 0) = 0
			INNER JOIN dbo.Stockline Stk WITH (NOLOCK) ON Stk.StockLineId = SOBII.StocklineId
			LEFT JOIN dbo.CreditMemo CM WITH (NOLOCK) ON CM.InvoiceId = BI.BillingInvoicingId AND CM.[Status] = 'Posted'
			WHERE BI.InvoiceStatus = 'Invoiced' AND ISNULL(BI.IsVersionIncrease, 0) = 0 AND ISNULL(BI.IsPerformaInvoice, 0) = 0
			AND BI.ModuleId IN (@SalesOrderModuleId, @WorkOrderModuleId)
			AND CAST(BI.InvoiceDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND ISNULL(Stk.IsNonStock,0) = 0
		),
		InvoiceWithPercentageValue AS (
			SELECT DISTINCT
				IWS.*,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN SO.SalesPersonId
					WHEN @WorkOrderModuleId THEN WO.SalesPersonId
				END AS EmployeeId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.PrimarySalesRevenue,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.PrimarySalesRevenue,0)
				END AS EffectiveRevenuePercentageId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.PrimarySalesMargin,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.PrimarySalesMargin,0)
				END AS EffectiveMarginPercentageId
			FROM InvoicesSOWO IWS
			LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = IWS.ReferenceId AND IWS.ModuleId = @SalesOrderModuleId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = IWS.ReferenceId AND IWS.ModuleId = @WorkOrderModuleId
			WHERE 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.PrimarySalesRevenue,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.PrimarySalesRevenue,0) END) IS NOT NULL
			AND 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.PrimarySalesMargin,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.PrimarySalesMargin,0) END) IS NOT NULL

			 UNION ALL

			 SELECT DISTINCT
				IWS.*,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN SO.SecondarySalesPersonId
					WHEN @WorkOrderModuleId THEN WO.SecondarySalesPersonId
				END AS EmployeeId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.SecondarySalesRevenue,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.SecondarySalesRevenue,0)
				END AS EffectiveRevenuePercentageId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.SecondarySalesMargin,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.SecondarySalesMargin,0)
				END AS EffectiveMarginPercentageId
			FROM InvoicesSOWO IWS
			LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = IWS.ReferenceId AND IWS.ModuleId = @SalesOrderModuleId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = IWS.ReferenceId AND IWS.ModuleId = @WorkOrderModuleId
			WHERE 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.SecondarySalesRevenue,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.SecondarySalesRevenue,0) END) IS NOT NULL
			AND 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.SecondarySalesMargin,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.SecondarySalesMargin,0) END) IS NOT NULL

			UNION ALL

			SELECT DISTINCT
				IWS.*,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN SO.SalesAgentId
					WHEN @WorkOrderModuleId THEN WO.SalesAgentId
				END AS EmployeeId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.AgentSalesRevenue,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.AgentSalesRevenue,0)
				END AS EffectiveRevenuePercentageId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.AgentSalesMargin,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.AgentSalesMargin,0)
				END AS EffectiveMarginPercentageId
			FROM InvoicesSOWO IWS
			LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = IWS.ReferenceId AND IWS.ModuleId = @SalesOrderModuleId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = IWS.ReferenceId AND IWS.ModuleId = @WorkOrderModuleId
			WHERE 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.AgentSalesRevenue,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.AgentSalesRevenue,0) END) IS NOT NULL
			AND 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.AgentSalesMargin,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.AgentSalesMargin,0) END) IS NOT NULL

			UNION ALL

			SELECT DISTINCT
				IWS.*,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN SO.CustomerSeviceRepId
					WHEN @WorkOrderModuleId THEN WO.CSRId
				END AS EmployeeId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.CSRSalesRevenue,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.CSRSalesRevenue,0)
				END AS EffectiveRevenuePercentageId,
				CASE IWS.ModuleId
					WHEN @SalesOrderModuleId THEN ISNULL(SO.CSRSalesMargin,0)
					WHEN @WorkOrderModuleId THEN ISNULL(WO.CSRSalesMargin,0)
				END AS EffectiveMarginPercentageId
			FROM InvoicesSOWO IWS
			LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = IWS.ReferenceId AND IWS.ModuleId = @SalesOrderModuleId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = IWS.ReferenceId AND IWS.ModuleId = @WorkOrderModuleId
			WHERE 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.CSRSalesRevenue,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.CSRSalesRevenue,0) END) IS NOT NULL
			AND 
				(CASE IWS.ModuleId WHEN @SalesOrderModuleId THEN ISNULL(SO.CSRSalesMargin,0)
								  WHEN @WorkOrderModuleId THEN ISNULL(WO.CSRSalesMargin,0) END) IS NOT NULL
	  ),
	  InvoiceWithEffectivePercent AS (
			SELECT DISTINCT
				IWS.*
			FROM InvoiceWithPercentageValue IWS
			LEFT JOIN Employee E WITH (NOLOCK) ON E.EmployeeId = IWS.EmployeeId
		), rptCTE (TotalRecordsCount, MasterCompanyId, ActivityTypeId, InvoiceDate, DocNum, EmployeeId, Salesperson, Customer, RevenueAmount, RevenueRate, RevenueCommission,
		MarginAmount, MarginRate, MarginCommission, TotalCommission, 
		level1, level2, level3, level4, level5, level6, level7, level8,level9, level10) 
		AS (
      SELECT DISTINCT 0 AS TotalRecordsCount,
		E.MasterCompanyId,
		BI.ActivityTypeId,
		BI.InvoiceDate,
		BI.DocNum,
		E.EmployeeId,
		(E.FirstName + ' ' + E.LastName) AS Salesperson,
		C.[Name] AS Customer,
    	SUM(ISNULL(BI.GrandTotal,0)) AS RevenueAmount,
		RP.PercentValue AS RevenueRate,
		SUM(ISNULL(BI.GrandTotal,0) * (ISNULL(RP.PercentValue,0) / 100.00)) AS RevenueCommission,
		SUM(ISNULL(BI.PartCost,0)) AS MarginAmount,
		MP.PercentValue AS MarginRate,
		SUM((ISNULL(BI.PartCost,0)) * (ISNULL(MP.PercentValue,0) / 100.00)) AS MarginCommission,
		(SUM(ISNULL(BI.GrandTotal,0) * (ISNULL(RP.PercentValue,0) / 100.00)) + SUM(ISNULL(BI.PartCost,0) * (ISNULL(MP.PercentValue,0) / 100.00))) AS TotalCommission,
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
		FROM InvoiceWithEffectivePercent BI
		JOIN DBO.Employee E WITH (NOLOCK) ON BI.EmployeeId = E.EmployeeId
		JOIN DBO.Customer C WITH (NOLOCK) ON BI.CustomerId = C.CustomerId
		LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON BI.ReferenceId = SO.SalesOrderId AND BI.ModuleId = @SalesOrderModuleId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
		LEFT JOIN dbo.[Percent] RP WITH (NOLOCK) ON RP.PercentId = BI.EffectiveRevenuePercentageId
		LEFT JOIN dbo.[Percent] MP WITH (NOLOCK) ON MP.PercentId = BI.EffectiveMarginPercentageId
		WHERE 1 = 1
			AND  ((ISNULL(@Employee, '') = '' OR BI.EmployeeId = @Employee) 
			AND  (ISNULL(@Customer, '') = '' OR BI.CustomerId = @Customer)
			)
			AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

			GROUP BY E.MasterCompanyId, E.EmployeeId, BI.ActivityTypeId, BI.InvoiceDate, BI.DocNum, E.FirstName, E.LastName, C.[Name], RP.PercentValue, MP.PercentValue, 
               MSD.Level1Name, MSD.Level2Name, MSD.Level3Name, MSD.Level4Name, 
               MSD.Level5Name, MSD.Level6Name, MSD.Level7Name, MSD.Level8Name, 
               MSD.Level9Name, MSD.Level10Name,E.EmployeeExpIds, BI.EffectiveRevenuePercentageId

			UNION ALL

			SELECT DISTINCT 0 AS TotalRecordsCount,
			E.MasterCompanyId,
			BI.ActivityTypeId,
			BI.InvoiceDate,
			BI.DocNum,
			E.EmployeeId,
			(E.FirstName + ' ' + E.LastName) AS Salesperson,
			C.[Name] AS Customer,
			SUM(ISNULL(BI.GrandTotal,0)) AS RevenueAmount,
			RP.PercentValue AS RevenueRate,
			SUM(ISNULL(BI.GrandTotal,0) * (ISNULL(RP.PercentValue,0) / 100.00)) AS RevenueCommission,
			(SUM(ISNULL(BI.GrandTotal,0)) - (ISNULL(SUM(ISNULL(WOC.PartsCost,0)),0) 
                     + ISNULL(SUM(ISNULL(WOC.LaborCost,0)),0))) AS MarginAmount,
			MP.PercentValue AS MarginRate,
			((SUM(ISNULL(BI.GrandTotal,0)) - (ISNULL(SUM(ISNULL(WOC.PartsCost,0)),0) 
                     + ISNULL(SUM(ISNULL(WOC.LaborCost,0)),0))) * (ISNULL(MP.PercentValue,0) / 100.00)) AS MarginCommission,
			(SUM(ISNULL(BI.GrandTotal,0) * (ISNULL(RP.PercentValue,0) / 100.00)) + ((SUM(ISNULL(BI.GrandTotal,0)) - (ISNULL(SUM(ISNULL(WOC.PartsCost,0)),0) 
                     + ISNULL(SUM(ISNULL(WOC.LaborCost,0)),0))) * (ISNULL(MP.PercentValue,0) / 100.00))) AS TotalCommission,
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
			FROM InvoiceWithEffectivePercent BI
			JOIN DBO.Employee E WITH (NOLOCK) ON BI.EmployeeId = E.EmployeeId
			JOIN DBO.Customer C WITH (NOLOCK) ON BI.CustomerId = C.CustomerId
			LEFT JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON BI.SubReferenceId = WOP.ID AND BI.ModuleId = @WorkOrderModuleId
			INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID
			LEFT JOIN (
				SELECT WOPartNoId,
					   SUM(ISNULL(PartsCost,0)) AS PartsCost,
					   SUM(ISNULL(LaborCost,0)) AS LaborCost,
					   SUM(ISNULL(OverHeadCost,0)) AS OverHeadCost
				FROM dbo.WorkOrderCostDetails WITH (NOLOCK)
				GROUP BY WOPartNoId
			) WOC ON WOC.WOPartNoId = BI.SubReferenceId
			LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			LEFT JOIN dbo.[Percent] RP WITH (NOLOCK) ON RP.PercentId = BI.EffectiveRevenuePercentageId
			LEFT JOIN dbo.[Percent] MP WITH (NOLOCK) ON MP.PercentId = BI.EffectiveMarginPercentageId
			WHERE 1 = 1
			AND  ((ISNULL(@Employee, '') = '' OR BI.EmployeeId = @Employee) 
			AND  (ISNULL(@Customer, '') = '' OR BI.CustomerId = @Customer)
			)
			AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

			GROUP BY E.MasterCompanyId, E.EmployeeId, BI.ActivityTypeId, BI.InvoiceDate, BI.DocNum, E.FirstName, E.LastName, C.[Name], RP.PercentValue, MP.PercentValue, 
               MSD.Level1Name, MSD.Level2Name, MSD.Level3Name, MSD.Level4Name, 
               MSD.Level5Name, MSD.Level6Name, MSD.Level7Name, MSD.Level8Name, 
               MSD.Level9Name, MSD.Level10Name,E.EmployeeExpIds
			)
			,FinalCTE(TotalRecordsCount, MasterCompanyId, EmployeeId, ActivityTypeId, InvoiceDate, DocNum, Salesperson, Customer, RevenueAmount, RevenueRate, RevenueCommission,
				 MarginAmount, MarginRate, MarginCommission, TotalCommission,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10) 

			  AS (SELECT DISTINCT TotalRecordsCount, MasterCompanyId, EmployeeId, ActivityTypeId, InvoiceDate, DocNum, Salesperson, Customer, RevenueAmount, RevenueRate, RevenueCommission,
				 MarginAmount, MarginRate, MarginCommission, TotalCommission,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10 FROM rptCTE)
			, WithTotal (MasterCompanyId, TotalRevenueAmount, TotalRevenueCommission, TotalMarginAmount, TotalMarginCommission, GrandTotalCommission)
			AS (SELECT MasterCompanyId,
			FORMAT(SUM(RevenueAmount), 'N', 'en-us') TotalRevenueAmount,
			FORMAT(SUM(RevenueCommission), 'N', 'en-us') TotalRevenueCommission,
			FORMAT(SUM(MarginAmount), 'N', 'en-us') TotalMarginAmount,
			FORMAT(SUM(MarginCommission), 'N', 'en-us') TotalMarginCommission,
			FORMAT(SUM(TotalCommission), 'N', 'en-us') GrandTotalCommission
			FROM FinalCTE  
			GROUP BY MasterCompanyId)

			, FinalWithGrp AS (SELECT COUNT(2) OVER () AS TotalRecordsCount, FC.MasterCompanyId, FC.EmployeeId,
				CASE WHEN FC.ActivityTypeId = 1 THEN 'MRO Activity' WHEN FC.ActivityTypeId = 2 THEN 'Brokering' ELSE 'Manafacturing' END ActivityType, 
				InvoiceDate, DocNum, Salesperson AS EmployeeName, FC.Customer, 
				FORMAT(ISNULL(RevenueAmount,0) , 'N', 'en-us') Revenueamount, 
				FORMAT(ISNULL(RevenueRate,0) , 'N', 'en-us') Revenuerate, 
				FORMAT(ISNULL(RevenueCommission,0) , 'N', 'en-us') Revenuecommission,
				FORMAT(ISNULL(MarginAmount,0) , 'N', 'en-us') Marginamount, 
				FORMAT(ISNULL(MarginRate,0) , 'N', 'en-us') Marginrate, 
				FORMAT(ISNULL(MarginCommission,0) , 'N', 'en-us') Margincommission, 
				FORMAT(ISNULL(TotalCommission,0) , 'N', 'en-us') Totalcommission,
				level1, level2, level3, level4, level5, level6, level7, level8,level9, level10,
				WC.TotalRevenueAmount,
				WC.TotalRevenueCommission,
				WC.TotalMarginAmount,
				WC.TotalMarginCommission,
				WC.GrandTotalCommission
		    FROM FinalCTE FC
			INNER JOIN WithTotal WC ON FC.MasterCompanyId = WC.MasterCompanyId)
			
			, BeforeFinalWithGrp AS (SELECT COUNT(2) OVER () AS TotalRecordsCount, FC.MasterCompanyId, FC.EmployeeId,
				 CASE WHEN FC.ActivityTypeId = 1 THEN 'MRO Activity' WHEN FC.ActivityTypeId = 2 THEN 'Brokering' ELSE 'Manafacturing' END ActivityType, 
				 Salesperson AS EmployeeName,
				 Customer,
				 InvoiceDate, 
				 DocNum,
				 SUM(RevenueAmount) Revenueamount, 
				 SUM(RevenueRate) Revenuerate, 
				 ISNULL(SUM(RevenueCommission), 0) Revenuecommission,
				 SUM(MarginAmount) Marginamount, 
				 SUM(MarginRate) Marginrate, 
				 SUM(MarginCommission) Margincommission, 
				 SUM(TotalCommission) Totalcommission,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10,
				 WC.TotalRevenueAmount,
				 WC.TotalRevenueCommission,
				 WC.TotalMarginAmount,
				 WC.TotalMarginCommission,
				 WC.GrandTotalCommission
		    FROM FinalCTE FC
			INNER JOIN WithTotal WC ON FC.MasterCompanyId = WC.MasterCompanyId
			GROUP BY FC.MasterCompanyId, FC.EmployeeId, FC.ActivityTypeId, Salesperson, Customer, InvoiceDate, DocNum, level1, level2, level3, level4, level5, level6, level7, level8,level9, level10,
			TotalRevenueAmount, TotalRevenueCommission, TotalMarginAmount, TotalMarginCommission, GrandTotalCommission)

			SELECT * INTO #BeforeFinalWithGrp FROM BeforeFinalWithGrp;

			IF ISNULL(@PageSize,0) = 0
			BEGIN
				SELECT @PageSize = COUNT(1)
				FROM #BeforeFinalWithGrp;
			END

		    SELECT COUNT(2) OVER () AS TotalRecordsCount, MasterCompanyId, EmployeeId, ActivityType, Customer, EmployeeName, 
				InvoiceDate DocDate, DocNum,
				FORMAT(ISNULL(Revenueamount,0) , 'N', 'en-us') Revenueamount, 
				FORMAT(ISNULL(Revenuerate,0) , 'N', 'en-us') Revenuerate, 
				FORMAT(ISNULL(Revenuecommission,0) , 'N', 'en-us') Revenuecommission,
				FORMAT(ISNULL(Marginamount,0) , 'N', 'en-us') Marginamount, 
				FORMAT(ISNULL(Marginrate,0) , 'N', 'en-us') Marginrate, 
				FORMAT(ISNULL(Margincommission,0) , 'N', 'en-us') Margincommission, 
				FORMAT(ISNULL(Totalcommission,0) , 'N', 'en-us') AS Totalcommission,
				level1, level2, level3, level4, level5, level6, level7, level8,level9, level10,
				TotalRevenueAmount, TotalRevenueCommission, TotalMarginAmount, TotalMarginCommission, GrandTotalCommission
		    FROM #BeforeFinalWithGrp
			ORDER BY EmployeeId DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
  END TRY  
  
  BEGIN CATCH
    DECLARE @ErrorLogID int,
    @DatabaseName varchar(100) = DB_NAME(),
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    @AdhocComments varchar(150) = '[usprpt_GetEmployeeCommissionReport_IncludeCustomerAndInvoiceDetails]',
    @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) + 
    '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) + 
    '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) + 
    '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),
    @ApplicationName varchar(100) = 'PAS' 
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
        @AdhocComments = @AdhocComments,
        @ProcedureParameters = @ProcedureParameters,
        @ApplicationName = @ApplicationName,
        @ErrorLogID = @ErrorLogID OUTPUT;
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
    RETURN (1);
  END CATCH
END