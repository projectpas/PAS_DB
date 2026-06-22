/*************************************************************           
 ** File:   [AutoCompleteDropdownsForPOAndRONumber]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used retrieve PurchaseOrder and RepairOrder List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   26-Dec-2024            
 ** PARAMETERS: @StartWith varchar(50),@Count VARCHAR(10) = '0',@Idlist VARCHAR(max) = '0',@MasterCompanyId bigint            
 ** RETURN VALUE:             
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	2    26-Dec-2024   RAJESH GAMI    CREATED 	
	3    19-Jun-2026   Abhishek Jirawla  Adding IsPiecePart condition in RepairOrderPart table 
     
--  EXEC [AutoCompleteDropdownsForPOAndRONumberByVendorId] '','30','',1,3653

**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsForPOAndRONumberByVendorId]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId INT,
@VendorId BIGINT
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON
	 BEGIN TRY
		 DECLARE @POModuleId INT = 0,@ROModuleId INT = 0,@POCloseStatusId INT = 1,@ROCloseStatusId INT = 1,@POModuleName Varchar(50) = 'Purchase Order',@ROModuleName Varchar(50) = 'Repair Order';

		 SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'PurchaseOrder';
		 SELECT @ROModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'RepairOrder';
		 SELECT @POCloseStatusId = [POStatusId] FROM [dbo].[POStatus] WHERE UPPER([Description]) = UPPER('Closed');
         SELECT @ROCloseStatusId = [ROStatusId] FROM [dbo].[ROStatus] WHERE UPPER([Description]) = UPPER('Closed');
		 		 		 		 
		 IF(@Count = '0') 
		 BEGIN
			SET @Count = '20';	
		 END	

		SELECT DISTINCT TOP 20 
		       PO.[PurchaseOrderId] AS [value],
               PO.[PurchaseOrderNumber] AS [label],
			   @POModuleId AS ModuleId,
			   1 as IsPurchaseOrder,
			   @POModuleName AS ReferenceModuleName,PO.CreatedDate,
			   PO.FunctionalCurrencyId as CurrencyId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) 
        JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON PO.[PurchaseOrderId] = POP.[PurchaseOrderId] 
	    WHERE PO.[MasterCompanyId] = @MasterCompanyId 
		  AND PO.[StatusId] != @POCloseStatusId AND PO.VendorId = @VendorId 
		  AND (ISNULL(PO.[IsActive],0) = 1 AND ISNULL(PO.[IsDeleted],0) = 0 		 
		  AND (PO.[PurchaseOrderNumber] LIKE ('%' + @StartWith + '%')))
		
		UNION     

		SELECT DISTINCT  
			   PO.[PurchaseOrderId] AS [value],
               PO.[PurchaseOrderNumber] AS [label],
			   @POModuleId AS ModuleId,
			   1 as IsPurchaseOrder,
			   @POModuleName AS ReferenceModuleName,PO.CreatedDate
			   ,PO.FunctionalCurrencyId as CurrencyId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) 
        JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON PO.[PurchaseOrderId] = POP.[PurchaseOrderId] 
		WHERE PO.[MasterCompanyId] = @MasterCompanyId 
		  AND PO.[StatusId] != @POCloseStatusId  AND PO.VendorId = @VendorId
		  AND PO.PurchaseOrderId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
			
		UNION

		SELECT DISTINCT TOP 20 
			   RO.[RepairOrderId] AS [value],
               RO.[RepairOrderNumber] AS [label],
			   @ROModuleId AS ModuleId,
			   0 as IsPurchaseOrder,
			   @ROModuleName AS ReferenceModuleName,RO.CreatedDate
			   ,RO.FunctionalCurrencyId as CurrencyId
		  FROM [dbo].[RepairOrder] RO WITH(NOLOCK) 
          JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON RO.[RepairOrderId] = ROP.[RepairOrderId]  AND ISNULL(ROP.[IsPiecePart], 0) = 0			
		 WHERE RO.[MasterCompanyId] = @MasterCompanyId 
		   AND RO.[StatusId] != @ROCloseStatusId AND RO.VendorId = @VendorId 
		   AND (RO.[IsActive] = 1 AND ISNULL(RO.[IsDeleted],0) = 0 
		   AND (RO.[RepairOrderNumber] LIKE ('%' + @StartWith + '%')))

		UNION
		
		SELECT DISTINCT  
			   RO.RepairOrderId AS [value],
               RO.RepairOrderNumber AS [label],
			   @ROModuleId AS ModuleId,
			   0 as IsPurchaseOrder,
			   @ROModuleName AS ReferenceModuleName,RO.CreatedDate
			   ,RO.FunctionalCurrencyId as CurrencyId
		  FROM [dbo].[RepairOrder] RO WITH(NOLOCK) 
          JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId  AND ISNULL(ROP.[IsPiecePart], 0) = 0
		 WHERE RO.[MasterCompanyId] = @MasterCompanyId  
		   AND RO.[StatusId] != @ROCloseStatusId AND RO.VendorId = @VendorId  
		   AND RO.[RepairOrderId] IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				
		ORDER BY CreatedDate DESC

	END TRY 
	BEGIN CATCH 
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsForPOAndRONumberByVendorId'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') AS VARCHAR(100))			  
			   + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
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