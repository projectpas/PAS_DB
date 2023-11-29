/*************************************************************                   
 ** File:   [USP_GetChekPartandAddress]                   
 ** Author:   Shrey Chandegara        
 ** Description:             
 ** Purpose:                 
 ** Date:   20-09-2023                
                  
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author   Change Description                    
 ** --   --------     -------   --------------------------------                  
    1    04/05/2023   Shrey Chandegara  Created        
             
 EXECUTE USP_GetChekPartandAddress 2046,'frompo'     
**************************************************************/         
Create     PROCEDURE [dbo].[USP_GetChekPartandAddress]      
@ReferenceId BIGINT,
@View  VARCHAR (50) = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
   DECLARE @chekpart BIT = 0;      
   DECLARE @popart VARCHAR(50) = NULL;      
   DECLARE @shipadd VARCHAR(50) = NULL;      
   DECLARE @billadd VARCHAR(50) = NULL;    
   
  BEGIN TRY      
  BEGIN TRANSACTION      
   BEGIN       



		IF @View = 'frompo'
			BEGIN
				SET @popart = (SELECT TOP 1 PurchaseOrderPartRecordId FROM PurchaseOrderPart POP WHERE POP.PurchaseOrderId = @ReferenceId)
				print @popart
				IF ISNULL(@popart,0) <> 0
					BEGIN
						SET @shipadd = (SELECT TOP 1 AllAddressId FROM AllAddress A WHERE A.ReffranceId = @ReferenceId AND A.IsShippingAdd = 1 AND A.ModuleId = 13)
						print @shipadd
						SET @billadd = (SELECT TOP 1 AllAddressId FROM AllAddress A WHERE A.ReffranceId = @ReferenceId AND A.IsShippingAdd = 0 AND A.ModuleId = 13)
						print @billadd 
						IF ISNULL(@shipadd,0) <> 0 AND ISNULL(@billadd,0) <> 0
							BEGIN
								SET @chekpart = 1
							END
						ELSE
							BEGIN
								SET @chekpart = 0
							END
					END
				ELSE
					BEGIN
						SET @chekpart = 0
					END
			END
			ELSE IF @View = 'fromro'
			BEGIN
				SET @popart = (SELECT TOP 1 RepairOrderPartRecordId FROM RepairOrderPart ROP WHERE ROP.RepairOrderId = @ReferenceId)
				print @popart
				IF ISNULL(@popart,0) <> 0
					BEGIN
						SET @shipadd = (SELECT TOP 1 AllAddressId FROM AllAddress A WHERE A.ReffranceId = @ReferenceId AND A.IsShippingAdd = 1 AND A.ModuleId = 14)
						print @shipadd
						SET @billadd = (SELECT TOP 1 AllAddressId FROM AllAddress A WHERE A.ReffranceId = @ReferenceId AND A.IsShippingAdd = 0 AND A.ModuleId = 14)
						print @billadd 
						IF ISNULL(@shipadd,0) <> 0 AND ISNULL(@billadd,0) <> 0
							BEGIN
								SET @chekpart = 1
							END
						ELSE
							BEGIN
								SET @chekpart = 0
							END
					END
				ELSE
					BEGIN
						SET @chekpart = 0
					END
			END
			SELECT @chekpart as 'chekpart'
                      
   END      
  COMMIT  TRANSACTION      
      
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    --PRINT 'ROLLBACK'      
    ROLLBACK TRAN;   
	 
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
      
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'USP_GetChekPartandAddress'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''      
              , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
      
              exec spLogException       
                       @DatabaseName   = @DatabaseName      
                     , @AdhocComments   = @AdhocComments      
             , @ProcedureParameters  = @ProcedureParameters      
                     , @ApplicationName         = @ApplicationName      
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;      
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
              RETURN(1);      
  END CATCH      
END