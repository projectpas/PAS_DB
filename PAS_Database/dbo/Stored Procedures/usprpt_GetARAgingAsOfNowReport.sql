/*************************************************************           
 ** File:   [usprpt_GetARAgingAsOfNowReport]           
 ** Author:   HEMANT SALIYA  
 ** Description: Get Data for AR Agging Report  
 ** Purpose:         
 ** Date:   11-03-2024       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 11-03-2024		HEMANT SALIYA  		Created
     
exec usprpt_GetARAgingAsOfNowReport @mastercompanyid=1,@id=N'3/11/2024',@id2=N'',@id3=0,@strFilter=N'1,5,6,20,22,52,53!2,7,8,9!3,11,10!4,12,13!!!!!!'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetARAgingAsOfNowReport]
	@mastercompanyid INT,
	@id DATETIME2,
	@id2 VARCHAR(100),
	@id3 bit,
	@strFilter VARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  DECLARE @CustomerId VARCHAR(40) = NULL;
  DECLARE @AsOfDate DATETIME2 = GETUTCDATE();
  DECLARE @TypeId INT = NULL;
  DECLARE @CMPostedStatusId INT;
  DECLARE @ExcludeCredit INT;

  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';

  SET @AsOfDate  = @id ;
  SET @CustomerId = 3385;
  IF(ISNULL(@ExcludeCredit,0) = 0)      
  BEGIN 	
		SET @ExcludeCredit = 1;      
  END

  BEGIN TRY

		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END

		CREATE TABLE #TEMPMSFilter(        
				ID BIGINT  IDENTITY(1,1),        
				LevelIds VARCHAR(MAX)			 
			) 

		INSERT INTO #TEMPMSFilter(LevelIds)
		SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

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
		@Level10 VARCHAR(MAX) = NULL 

		SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
		SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
		SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
		SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
		SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
		SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
		SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
		SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
		SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
		SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10 

		DECLARE @SOMSModuleID BIGINT ; -- = 17 Sales Order MS Module ID 
		DECLARE @WOMSModuleID BIGINT ; -- = 12 Work Order MS Module ID  
		DECLARE @CMMSModuleID BIGINT ; -- = 61 CM MS Module ID  

		SELECT @WOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='WORKORDERMPN';
		SELECT @SOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='SALESORDER ';
		SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='CREDITMEMOHEADER';

		IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecords') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPInvoiceRecords
		END

		CREATE TABLE #TEMPInvoiceRecords(        
		ID BIGINT IDENTITY(1,1),      
		BillingInvoicingId BIGINT NOT NULL,
		CustomerId BIGINT NULL,
		CustomerName VARCHAR(200),
		CustomerCode VARCHAR(50),
		CustomerType VARCHAR(50),
		CurrencyCode VARCHAR(50),
		BalanceAmount DECIMAL(18, 2) NULL,
		CurrentAmount DECIMAL(18, 2) NULL,
		PaymentAmount DECIMAL(18, 2) NULL,
		InvoiceNo VARCHAR(50),
		InvoiceDate DATETIME2,
		NetDays INT NULL,
		Amountlessthan0days DECIMAL(18, 2) NULL,
		Amountlessthan30days DECIMAL(18, 2) NULL,
		Amountlessthan60days DECIMAL(18, 2) NULL,
		Amountlessthan90days DECIMAL(18, 2) NULL,
		Amountlessthan120days DECIMAL(18, 2) NULL,
		Amountmoerthan120days DECIMAL(18, 2) NULL,
		UpdatedBy VARCHAR(50) NULL,
		ManagementStructureId BIGINT NULL,
		DocType VARCHAR(200) NULL,
		CustomerRef VARCHAR(100),
		Salesperson VARCHAR(100),
		CreaditTerms VARCHAR(100),
		FixRateAmount DECIMAL(18, 2) NULL,
		InvoiceAmount DECIMAL(18, 2) NULL,
		CMAmount DECIMAL(18, 2) NULL,
		CreditMemoAmount DECIMAL(18, 2) NULL,
		CreditMemoUsed DECIMAL(18, 2) NULL,
		FROMDebit DECIMAL(18, 2) NULL,
		DueDate DATETIME2,
		level1 VARCHAR(500) NULL,
		level2 VARCHAR(500) NULL,
		level3 VARCHAR(500) NULL,
		level4 VARCHAR(500) NULL,
		level5 VARCHAR(500) NULL,
		level6 VARCHAR(500) NULL,
		level7 VARCHAR(500) NULL,
		level8 VARCHAR(500) NULL,
		level9 VARCHAR(500) NULL,
		level10 VARCHAR(500) NULL,
		MasterCompanyId INT NULL,
		StatusId BIGINT NULL,
		IsCreditMemo BIT NULL,
		InvoicePaidAmount DECIMAL(18, 2) NULL,
		ModuleTypeId INT NULL,
		LegalEntityName VARCHAR(MAX) NULL
		
		) 

		-- WO IONVOICE DETAILS
		INSERT INTO #TEMPInvoiceRecords(BillingInvoicingId, CustomerId ,CustomerName ,CustomerCode ,CustomerType ,CurrencyCode ,BalanceAmount, CurrentAmount, PaymentAmount ,
		InvoiceNo ,InvoiceDate ,NetDays ,Amountlessthan0days ,Amountlessthan30days ,Amountlessthan60days ,Amountlessthan90days ,Amountlessthan120days,
		Amountmoerthan120days,UpdatedBy ,ManagementStructureId ,DocType ,CustomerRef ,Salesperson ,CreaditTerms ,FixRateAmount ,InvoiceAmount , CMAmount ,CreditMemoAmount,
		CreditMemoUsed ,FROMDebit ,DueDate ,level1 ,level2 ,level3 ,level4 ,level5 ,level6 ,level7 ,level8 ,level9 ,level10 ,MasterCompanyId ,StatusId ,
		IsCreditMemo,InvoicePaidAmount, ModuleTypeId, LegalEntityName)
		SELECT DISTINCT WOBI. BillingInvoicingId,
						C.CustomerId,  						
						UPPER(ISNULL(C.[Name],'')),      
		                UPPER(ISNULL(C.CustomerCode,'')),
						UPPER(CT.CustomerTypeName),      
		                UPPER(CR.Code), 
						WOBI.GrandTotal,      
		                ((ISNULL(WOBI.GrandTotal, 0) - ISNULL(WOBI.RemainingAmount, 0)) + ISNULL(WOBI.CreditMemoUsed, 0)),      
		                ISNULL(WOBI.RemainingAmount, 0) + ISNULL(WOBI.CreditMemoUsed, 0),      
		                UPPER(WOBI.InvoiceNo),      
		                WOBI.InvoiceDate AS InvoiceDate,      
		                ISNULL(CTM.NetDays,0) AS NetDays,					
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN WOBI.RemainingAmount ELSE 0 END),
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN WOBI.RemainingAmount ELSE 0 END),
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN WOBI.RemainingAmount ELSE 0 END),
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN WOBI.RemainingAmount ELSE 0 END),
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN WOBI.RemainingAmount ELSE 0 END),
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
															WHEN CTM.Code='CIA' THEN -1
															WHEN CTM.Code='CreditCard' THEN -1
															WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN WOBI.RemainingAmount	ELSE 0 END),

						UPPER(C.UpdatedBy) AS UpdatedBy,      
						--(WOP.ManagementStructureId),     
						0,
						UPPER('AR-Inv'),      
						'',
						--UPPER(WOP.CustomerReference),      
						UPPER(ISNULL(EMP.FirstName,'Unassigned')),      
						UPPER(CTM.Name),      
						'0.000000',      
						WOBI.GrandTotal,      
						0,
						0,
						ISNULL(WOBI.CreditMemoUsed,0) AS CreditMemoUsed,
						0,
						--(CASE WHEN ISNULL((WOBI.RemainingAmount + ISNULL(WOBI.CreditMemoUsed,0)+ ISNULL(B.CMAmount,0)),0) > 0 THEN (CASE WHEN ISNULL(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
						DATEADD(DAY, CTM.NetDays,WOBI.InvoiceDate),     
						'' AS level1,        
						'' AS level2,       
						'' AS level3,       
						'' AS level4,       
						'' AS level5,       
						'' AS level6,       
						'' AS level7,       
						'' AS level8,       
						'' AS level9,       
						'' AS level10,
						--UPPER(MSD.Level1Name) AS level1,        
						--UPPER(MSD.Level2Name) AS level2,       
						--UPPER(MSD.Level3Name) AS level3,       
						--UPPER(MSD.Level4Name) AS level4,       
						--UPPER(MSD.Level5Name) AS level5,       
						--UPPER(MSD.Level6Name) AS level6,       
						--UPPER(MSD.Level7Name) AS level7,       
						--UPPER(MSD.Level8Name) AS level8,       
						--UPPER(MSD.Level9Name) AS level9,       
						--UPPER(MSD.Level10Name) AS level10,
						WOBI.MasterCompanyId,
						0 AS IsCreditMemo,
						0 AS StatusId,
						0,
						1 AS 'WorkOrder',
						LegalEntityName = (SELECT   
						STUFF((SELECT DISTINCT ',' + LE.[Name]  
							FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
								JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = WOP.ManagementStructureId
								JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
								JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
							WHERE WOP.WorkOrderId = WO.WorkOrderId
							FOR XML PATH('')), 1, 1, ''))
		FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK)
			INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId      
			INNER JOIN [dbo].[Customer] C  WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
			INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId      
			INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId      
			INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId      
			INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID
			LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = WO.CreditTermId      
		    LEFT JOIN  [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WO.SalesPersonId      
		WHERE WO.CustomerId = ISNULL(@CustomerId, WO.CustomerId) AND WOBI.IsVersionIncrease = 0   
			AND WOBI.RemainingAmount > 0 AND WOBI.InvoiceStatus = 'Invoiced' 
			AND CAST(WOBI.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) AND WO.mastercompanyid = @mastercompanyid  			
			AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
			AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
			AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
			AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
			AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
			AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
			AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
			AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
			AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
			AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

		UPDATE  #TEMPInvoiceRecords SET InvoicePaidAmount = tmpcash.InvoicePaidAmount
			FROM( SELECT 
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',				  
				   IPS.SOBillingInvoicingId AS BillingInvoicingId
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
				JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = 1
				LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
			 WHERE CP.StatusId = 2 AND IPS.InvoiceType = 2 
			 GROUP BY IPS.SOBillingInvoicingId 
			) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

		UPDATE  #TEMPInvoiceRecords SET CreditMemoAmount = ISNULL(tmpcm.CMAmount, 0)
				FROM( SELECT SUM(CMD.Amount) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
						INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = WOBII.BillingInvoicingId AND TmpInv.ModuleTypeId = 1
					WHERE CMD.IsWorkOrder = 1 AND CM.CustomerId = TmpInv.CustomerId AND CM.StatusId = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

		-- SO IONVOICE DETAILS
		INSERT INTO #TEMPInvoiceRecords(BillingInvoicingId, CustomerId ,CustomerName ,CustomerCode ,CustomerType ,CurrencyCode ,BalanceAmount, CurrentAmount, PaymentAmount ,
		InvoiceNo ,InvoiceDate ,NetDays ,Amountlessthan0days ,Amountlessthan30days ,Amountlessthan60days ,Amountlessthan90days ,Amountlessthan120days,
		Amountmoerthan120days,UpdatedBy ,ManagementStructureId ,DocType ,CustomerRef ,Salesperson ,CreaditTerms ,FixRateAmount ,InvoiceAmount , CMAmount ,CreditMemoAmount,
		CreditMemoUsed ,FROMDebit ,DueDate ,level1 ,level2 ,level3 ,level4 ,level5 ,level6 ,level7 ,level8 ,level9 ,level10 ,MasterCompanyId ,StatusId ,
		IsCreditMemo,InvoicePaidAmount, ModuleTypeId, LegalEntityName)
		SELECT DISTINCT SOBI.SOBillingInvoicingId,
					C.CustomerId,  					
                    UPPER(ISNULL(C.[Name],'')),      
                    UPPER(ISNULL(C.CustomerCode,'')),      
                    UPPER(CT.CustomerTypeName),      
					UPPER(CR.Code),      
					SOBI.GrandTotal,      
					((ISNULL(SOBI.GrandTotal, 0) - ISNULL(SOBI.RemainingAmount, 0)) + ISNULL(SOBI.CreditMemoUsed,0)),      
					ISNULL(SOBI.RemainingAmount, 0) + ISNULL(SOBI.CreditMemoUsed,0),      
					UPPER(SOBI.InvoiceNo),      
					SOBI.InvoiceDate,      
					ISNULL(CTM.NetDays,0),      						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
							 WHEN CTM.Code='CIA' THEN -1
							 WHEN CTM.Code='CreditCard' THEN -1
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN SOBI.RemainingAmount ELSE 0 END),
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN SOBI.RemainingAmount ELSE 0 END),      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN SOBI.RemainingAmount ELSE 0 END),      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN SOBI.RemainingAmount ELSE 0 END),      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN SOBI.RemainingAmount ELSE 0 END),      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN SOBI.RemainingAmount ELSE 0 END),      
                    UPPER(C.UpdatedBy) AS UpdatedBy,      
					(SO.ManagementStructureId) AS ManagementStructureId,  					
					UPPER('AR-Inv') AS 'DocType',  
					'' AS 'CustomerRef',   
					--UPPER(sop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(SO.SalesPersonName,'Unassigned')) AS 'Salesperson',      
					UPPER(CTM.[Name]) AS 'Terms',      
					'0.000000' AS 'FixRateAmount',      
					SOBI.GrandTotal AS 'InvoiceAmount',      
					0 AS 'CMAmount',   
					0 AS CreditMemoAmount,
					SOBI.CreditMemoUsed,
					0 AS 'FROMDebit',
					--(CASE WHEN ISNULL((SOBI.RemainingAmount + ISNULL(SOBI.CreditMemoUsed,0) + Isnull(B.CMAmount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					DATEADD(DAY, CTM.NetDays,SOBI.InvoiceDate) AS 'DueDate',   
					'' AS level1,        
					'' AS level2,       
					'' AS level3,       
					'' AS level4,       
					'' AS level5,       
					'' AS level6,       
					'' AS level7,       
					'' AS level8,       
					'' AS level9,       
					'' AS level10,
					--UPPER(MSD.Level1Name) AS level1,        
					--UPPER(MSD.Level2Name) AS level2,       
					--UPPER(MSD.Level3Name) AS level3,       
					--UPPER(MSD.Level4Name) AS level4,       
					--UPPER(MSD.Level5Name) AS level5,       
					--UPPER(MSD.Level6Name) AS level6,       
					--UPPER(MSD.Level7Name) AS level7,       
					--UPPER(MSD.Level8Name) AS level8,       
					--UPPER(MSD.Level9Name) AS level9,       
					--UPPER(MSD.Level10Name) AS level10,
					SOBI.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId,
					0 AS InvoicePaidAmount,
					2 AS 'SalesOrder',
					LegalEntityName = (SELECT   
						STUFF((SELECT DISTINCT ',' + LE.[Name]  
							 FROM [dbo].[SalesOrderPart] SOP WITH (NOLOCK)
								JOIN [dbo].[Stockline] SL ON SL.StockLineId = SOP.StockLineId
								JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
								JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
								JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
							WHERE SOP.SalesOrderId = SO.SalesOrderId
							FOR XML PATH('')), 1, 1, ''))
				FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK)       
					INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId      
					INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId = SO.CustomerId      
					INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId      
					INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId      
					INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
					LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 
					LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON CTM.CreditTermsId = SO.CreditTermId      
				WHERE SO.CustomerId = ISNULL(@customerid, SO.CustomerId)
					AND SOBI.RemainingAmount > 0 AND SOBI.InvoiceStatus = 'Invoiced' AND ISNULL(SOBI.IsProforma,0) = 0 
					AND CAST(SOBI.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
					AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
					AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
					AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
					AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
					AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
					AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
					AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
					AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
					AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
					AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

		UPDATE  #TEMPInvoiceRecords SET InvoicePaidAmount = tmpcash.InvoicePaidAmount
			FROM( SELECT 
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',				  
				   IPS.SOBillingInvoicingId AS BillingInvoicingId
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
				JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = 2
				LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
			 WHERE CP.StatusId = 2 AND IPS.InvoiceType = 1 
			 GROUP BY IPS.SOBillingInvoicingId 
			) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

		UPDATE  #TEMPInvoiceRecords SET CreditMemoAmount = ISNULL(tmpcm.CMAmount, 0)
				FROM( SELECT SUM(CMD.Amount) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = 2
					WHERE CMD.IsWorkOrder = 0 AND CM.CustomerId = TmpInv.CustomerId AND CM.StatusId = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

		INSERT INTO #TEMPInvoiceRecords(BillingInvoicingId, CustomerId ,CustomerName ,CustomerCode ,CustomerType ,CurrencyCode ,BalanceAmount, CurrentAmount, PaymentAmount ,
		InvoiceNo ,InvoiceDate ,NetDays ,Amountlessthan0days ,Amountlessthan30days ,Amountlessthan60days ,Amountlessthan90days ,Amountlessthan120days,
		Amountmoerthan120days,UpdatedBy ,ManagementStructureId ,DocType ,CustomerRef ,Salesperson ,CreaditTerms ,FixRateAmount ,InvoiceAmount , CMAmount ,CreditMemoAmount,
		CreditMemoUsed ,FROMDebit ,DueDate ,level1 ,level2 ,level3 ,level4 ,level5 ,level6 ,level7 ,level8 ,level9 ,level10 ,MasterCompanyId ,StatusId ,
		IsCreditMemo,InvoicePaidAmount, ModuleTypeId, LegalEntityName)
		SELECT DISTINCT CM.CreditMemoHeaderId,
					C.CustomerId AS CustomerId,      
					UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
					UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
					UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode',      
					ISNULL(WOBI.GrandTotal,0) AS 'BalanceAmount',      
					(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0)  + ISNULL(WOBI.CreditMemoUsed,0)) AS 'CurrentlAmount',      
					ISNULL(WOBI.RemainingAmount,0) + ISNULL(WOBI.CreditMemoUsed,0)  AS 'PaymentAmount',      
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',      
					WOBI.InvoiceDate AS InvoiceDate,      
					ISNULL(CTM.NetDays,0) AS NetDays,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN WOBI.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN WOBI.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN WOBI.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN WOBI.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(CTM.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN WOBI.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
							 WHEN CTM.Code='CIA' THEN -1      
							 WHEN CTM.Code='CreditCard' THEN -1      
							 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN WOBI.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
					UPPER(C.UpdatedBy) AS UpdatedBy,      
					(CM.ManagementStructureId) AS ManagementStructureId,      
					UPPER('Credit-Memo') AS 'DocType',      
					'' AS 'CustomerRef',      
					UPPER(isnull(emp.FirstName,'Unassigned')) AS 'Salesperson',      
					CTM.Name AS 'Terms',  
					'0.000000' AS 'FixRateAmount',      
					CM.Amount AS 'InvoiceAmount', 
					CM.Amount AS 'CMAmount', 
					CM.Amount AS CreditMemoAmount,
					ISNULL(WOBI.CreditMemoUsed, 0) AS CreditMemoUsed,
					(CASE WHEN ISNULL((WOBI.RemainingAmount + ISNULL(WOBI.CreditMemoUsed,0) + Isnull(CMD.Amount,0)),0) > 0 THEN (CASE WHEN ISNULL(@ExcludeCredit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					NULL AS 'DueDate', 
					UPPER(MSD.Level1Name) AS level1,        
					UPPER(MSD.Level2Name) AS level2,       
					UPPER(MSD.Level3Name) AS level3,       
					UPPER(MSD.Level4Name) AS level4,       
					UPPER(MSD.Level5Name) AS level5,       
					UPPER(MSD.Level6Name) AS level6,       
					UPPER(MSD.Level7Name) AS level7,       
					UPPER(MSD.Level8Name) AS level8,       
					UPPER(MSD.Level9Name) AS level9,       
					UPPER(MSD.Level10Name) AS level10,
					WOBI.MasterCompanyId,
					1 AS IsCreditMemo,
					CM.StatusId,
					0 AS 'InvoicePaidAmount',
					3 AS 'WorkOrderCreditMemo',
					LE.[Name] AS LegalEntityName 
		 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				INNER JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId       
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId      
				INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId = WO.CustomerId   
				INNER JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = WO.CreditTermId      
				INNER JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WO.SalesPersonId      
				INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId      
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId      
				INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
				JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = CM.ManagementStructureId
				JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
				JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
		WHERE WO.CustomerId = ISNULL(@customerid, WO.CustomerId) AND CMD.IsWorkOrder = 1  
				AND CM.StatusId = @CMPostedStatusId		  
				AND (CASE WHEN @ExcludeCredit = 2 THEN ISNULL(CMD.Amount,0) END > 0 OR CASE WHEN @ExcludeCredit = 1 THEN ISNULL(CMD.Amount,0) END < 0)
				AND CAST(WOBI.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
				AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
				AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
				AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
				AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
				AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
				AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
				AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
				AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
				AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
				AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))	


		SELECT 
			--CASE WHEN ISNULL(IsCreditMemo, 0) = 1 THEN (ISNULL(InvoiceAmount, 0) - ISNULL(InvoicePaidAmount, 0)) 
			--		ELSE CASE WHEN StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CreditMemoAmount,0) END
			--		END AS 'BalanceAmount',
		* FROM #TEMPInvoiceRecords




		
		
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[usprpt_GetARAgingAsOfNowReport]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END