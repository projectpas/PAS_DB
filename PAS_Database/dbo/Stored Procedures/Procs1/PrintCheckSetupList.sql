/*************************************************************                   
 ** File:   [PrintCheckSetupList]                   
 ** Author:  unknown   
 ** Description: Get Data For Print Check Setup List
 ** Purpose:                 
 ** Date:     
 ** PARAMETERS:         
 ** RETURN VALUE:       
 **************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------   
	1                      unknown         Created            
	2    21-SEP-2023       Moin Bloch      Modified (Formated The SP AND ADDED MASTER COMPANY WISE DATA )
***************************************************************************************************/ 
CREATE   PROCEDURE [dbo].[PrintCheckSetupList]
@PageSize int,
@PageNumber int,
@SortColumn varchar(50)=null,
@SortOrder int,
--@StatusID int,
@GlobalFilter varchar(50) = null,
@StartNum varchar(50)=null,
@BankName varchar(50)=null,
@BankAccountNumber varchar(50)=null,
@GlAccount varchar(50)=null,
@BankRef varchar(50)=null,
@CcardPaymentRef varchar(50)=null,
@TypeName varchar(50)=null,
@MasterCompanyId int = null,
@EmployeeId bigint,
@APGLAccount varchar(50)=null,
@LastMSLevel varchar(50)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		--BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom INT;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @SortColumn IS NULL
				BEGIN
					Set @SortColumn = UPPER('CreatedDate')
				END 
				ELSE
				BEGIN 
					SET @SortColumn = UPPER(@SortColumn)
				END
				IF (@StartNum=0)
				BEGIN
					SET @StartNum = NULL
				END 

			 DECLARE @ModuleID varchar(500) ='65,66,67';

			;With Result AS(
				SELECT RRH.PrintingId,
				       RRH.StartNum,
					   RRH.[ConfirmStartNum],
					   RRH.BankId,
					   RRH.BankName,
					   RRH.BankAccountId,
					   RRH.BankAccountNumber,
					   RRH.GLAccountId,
					   RRH.GlAccount,
					   RRH.ConfirmBankAccInfo,
					   RRH.BankRef,
					   RRH.CcardPaymentRef,
					   RRH.[Type],
					   CASE WHEN RRH.[Type] = 1 THEN 'Check' WHEN RRH.[Type] = 2 THEN 'Wire' WHEN RRH.[Type] = 3 THEN 'Credit Card' ELSE '' END as 'TypeName',
					   RRH.MasterCompanyId,
					   RRH.CreatedBy,
					   RRH.CreatedDate,
					   RRH.UpdatedBy,
					   RRH.UpdatedDate,
					   CONCAT(G.AccountCode,' - ',G.AccountName)AS APGLAccount,
					   MSD.LastMSLevel,
					   MSD.AllMSlevels,
					   RRH.ManagementStructureId
				   FROM [dbo].[PrintCheckSetup] RRH WITH (NOLOCK)						
						LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH (NOLOCK) on RRH.BankId=lebl.LegalEntityBankingLockBoxId
						LEFT JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON lebl.GLAccountId = G.GLAccountId and lebl.AccountTypeId=2
						LEFT JOIN [dbo].[AccountingManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = RRH.PrintingId
						WHERE RRH.MasterCompanyId = @MasterCompanyId 
						),

						FinalResult AS (
						SELECT PrintingId, StartNum, [ConfirmStartNum], BankId, BankName, BankAccountId,BankAccountNumber, GLAccountId, GlAccount, ConfirmBankAccInfo,BankRef,CcardPaymentRef,
								Type, TypeName, MasterCompanyId, CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,APGLAccount,LastMSLevel,
						AllMSlevels,ManagementStructureId FROM Result
						WHERE ((@GlobalFilter <>'' AND ((StartNum LIKE '%' +@GlobalFilter+'%' ) OR 
							  ([BankName] LIKE '%' +@GlobalFilter+'%') OR
							  (BankAccountNumber LIKE '%' +@GlobalFilter+'%') OR
							  (GlAccount LIKE '%' +@GlobalFilter+'%') OR
							  (APGLAccount LIKE '%' +@GlobalFilter+'%') OR
							  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
							  (BankRef LIKE '%' +@GlobalFilter+'%') OR
							  (CcardPaymentRef LIKE '%'+@GlobalFilter+'%')))
							  OR   
							  (@GlobalFilter='' AND (ISNULL(@StartNum,'') ='' OR StartNum LIKE  '%'+ @StartNum+'%') AND 
							  (ISNULL(@TypeName,'') ='' OR TypeName LIKE '%'+@TypeName+'%') AND
							  (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND
							  (ISNULL(@BankAccountNumber,'') ='' OR BankAccountNumber like '%'+@BankAccountNumber+'%') AND
							  (ISNULL(@GlAccount,'') ='' OR GlAccount LIKE '%'+ @GlAccount+'%') AND
							  (ISNULL(@APGLAccount,'') ='' OR APGLAccount LIKE '%'+ @APGLAccount+'%') AND
							  (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%'+ @LastMSLevel+'%') AND
							  (ISNULL(@BankRef,'') ='' OR BankRef LIKE '%'+ @BankRef +'%')))),
									
						ResultCount AS (SELECT COUNT(PrintingId) AS NumberOfItems FROM FinalResult)
								SELECT PrintingId, StartNum, [ConfirmStartNum], BankId, BankName, BankAccountId,BankAccountNumber, GLAccountId, GlAccount, ConfirmBankAccInfo,BankRef,CcardPaymentRef,
								Type, TypeName, MasterCompanyId, CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,APGLAccount,LastMSLevel,
								AllMSlevels,ManagementStructureId, NumberOfItems FROM FinalResult, ResultCount

							ORDER BY  
							CASE WHEN (@SortOrder=1 AND @SortColumn='PRINTINGID') THEN PrintingId END DESC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='STARTNUM')  THEN StartNum END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='BANKNAME')  THEN BankName END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='TypeName')  THEN TypeName END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='BANKREF')  THEN BankRef END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='APGLAccount')  THEN APGLAccount END ASC,
							CASE WHEN (@SortOrder=1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,

							CASE WHEN (@SortOrder=-1 AND @SortColumn='PRINTINGID')  THEN PrintingId END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='STARTNUM')  THEN StartNum END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TypeName')  THEN TypeName END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='BANKNAME')  THEN BankName END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='APGLAccount')  THEN APGLAccount END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='BANKREF')  THEN BankRef END DESC
							OFFSET @RecordFrom ROWS 
							FETCH NEXT @PageSize ROWS ONLY
						END
		--	COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'VendorPaymentList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END