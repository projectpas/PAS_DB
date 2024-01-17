/*************************************************************           
 ** File:   [AutoCompleteDropdownsForPOAndRONumber]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used retrieve PurchaseOrder and RepairOrder List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   11-01-2024            
 ** PARAMETERS: @StartWith varchar(50),@Count VARCHAR(10) = '0',@Idlist VARCHAR(max) = '0',@MasterCompanyId bigint            
 ** RETURN VALUE:             
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11-01-2024   Moin Bloch     Created
     
--  EXEC [AutoCompleteDropdownsForPOAndRONumber] 'PO-00001','10','108',1

  exec dbo.AutoCompleteDropdownsForPOAndRONumber @StartWith=N'211',@Count=20,@Idlist=N'0',@MasterCompanyId=1
**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsForPOAndRONumber]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId INT 
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON
	 BEGIN TRY
		 DECLARE @POModuleId INT = 0,@ROModuleId INT = 0,@POOpenStatusId INT = 1,@ROOpenStatusId INT = 1;

		 SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'PurchaseOrder';
		 SELECT @ROModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'RepairOrder';
		 SELECT @POOpenStatusId = [POStatusId] FROM [dbo].[POStatus] WHERE UPPER([Description]) = UPPER('Open');
         SELECT @ROOpenStatusId = [ROStatusId] FROM [dbo].[ROStatus] WHERE UPPER([Description]) = UPPER('Open');
		 		 		 		 
		 IF(@Count = '0') 
		 BEGIN
			SET @Count = '20';	
		 END	

		SELECT DISTINCT TOP 20 
		       PO.[PurchaseOrderId] AS [value],
               PO.[PurchaseOrderNumber] AS [label],
			   @POModuleId AS ModuleId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) 
        JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON PO.[PurchaseOrderId] = POP.[PurchaseOrderId] 
	    WHERE PO.[MasterCompanyId] = @MasterCompanyId 
		  AND PO.[StatusId] = @POOpenStatusId 
		  AND (PO.[IsActive] = 1 AND ISNULL(PO.[IsDeleted],0) = 0 		 
		  AND (PO.[PurchaseOrderNumber] LIKE ('%' + @StartWith + '%')))
		
		UNION     

		SELECT DISTINCT  
			   PO.[PurchaseOrderId] AS [value],
               PO.[PurchaseOrderNumber] AS [label],
			   @POModuleId AS ModuleId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) 
        JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON PO.[PurchaseOrderId] = POP.[PurchaseOrderId] 
		WHERE PO.[MasterCompanyId] = @MasterCompanyId 
		  AND PO.[StatusId] = @POOpenStatusId  
		  AND PO.PurchaseOrderId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
			
		UNION

		SELECT DISTINCT TOP 20 
			   RO.[RepairOrderId] AS [value],
               RO.[RepairOrderNumber] AS [label],
			   @ROModuleId AS ModuleId
		  FROM [dbo].[RepairOrder] RO WITH(NOLOCK) 
          JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON RO.[RepairOrderId] = ROP.[RepairOrderId] 			
		 WHERE RO.[MasterCompanyId] = @MasterCompanyId 
		   AND RO.[StatusId] = @ROOpenStatusId   
		   AND (RO.[IsActive] = 1 AND ISNULL(RO.[IsDeleted],0) = 0 
		   AND (RO.[RepairOrderNumber] LIKE ('%' + @StartWith + '%')))

		UNION
		
		SELECT DISTINCT  
			   RO.RepairOrderId AS [value],
               RO.RepairOrderNumber AS [label],
			   @ROModuleId AS ModuleId
		  FROM [dbo].[RepairOrder] RO WITH(NOLOCK) 
          JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId 
		 WHERE RO.[MasterCompanyId] = @MasterCompanyId  
		   AND RO.[StatusId] = @ROOpenStatusId  
		   AND RO.[RepairOrderId] IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				
		ORDER BY [label]

	END TRY 
	BEGIN CATCH 
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsForPOAndRONumber'               
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