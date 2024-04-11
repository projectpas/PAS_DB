/*************************************************************           
 ** File:   SearchCreditMemoPNViewData         
 ** Author:  Moin
 ** Description: Get Credit Memo Filter Data
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Moin Bloch		Created
	2    09/04/2023   AMIT GHEDIYA      Updated to get from standaloneCM.
	3    09/15/2023   AMIT GHEDIYA      Updated to Cast.
	4    09/15/2024   HEAMNT SALIYA     Updated Status ID.
	
 -- exec SearchCreditMemoPNViewData 10,1,'CreatedDate',-1,'',1,null,null,'',null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,'',15,0,1	
**************************************************************/ 


CREATE       PROCEDURE [dbo].[SearchCreditMemoPNViewData]
	@PageSize int=NULL,
	@PageNumber int=NULL,
	@SortColumn varchar(50)=NULL, 
	@SortOrder int=NULL,
	@GlobalFilter varchar(50)=NULL,
	@StatusID int=NULL,
	@CreditMemoNumber varchar(50)=NULL,
	@IssueDate datetime=NULL,
	@Status varchar(50)=NULL,
	@Reason varchar(50)=NULL,
	@RMANumber varchar(50)=NULL,
	@WONum varchar(50)=NULL,
	@CustomerName varchar(50)=NULL,
	@PartNumber	varchar(50)=NULL,
	@PartDescription varchar(250)=NULL,
	@ReferenceNo varchar(50)=NULL,
	@Qty varchar(50),
	@UnitPrice varchar(50),
	@Amount varchar(50),
	@RequestedBy varchar(50)=NULL,
	@LastMSLevel varchar(50)=NULL,
	@Memo varchar(50)=NULL,
	@ReturnDate datetime=NULL,
	@MasterCompanyId int=NULL,
	@ViewType varchar(10)=NULL,
	@EmployeeId bigint=1,
	@IsDeleted bit=NULL,
	@IsActive bit=NULL,
	@ManufacturerName varchar(10)=NUL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY		
	  DECLARE @RecordFrom int; 
	  DECLARE @ModuleID varchar(500) ='61'
	 
	  Declare @Count Int;  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

	  if(@GlobalFilter is null)
	  begin
	  set @GlobalFilter='';
	  end

	  IF @SortColumn is null  
	  Begin  
	   Set @SortColumn = Upper('CreatedDate')  
	  End   
	  Else  
	  Begin   
	   Set @SortColumn = Upper(@SortColumn)  
	  End
	  IF (@StatusID=11 AND @Status='All')
	  BEGIN			
			SET @Status = ''
	  END
	  IF (@StatusID=11 OR @StatusID=0)
	  BEGIN
			SET @StatusID = NULL			
      END	

	 ;WITH Result AS(  
       SELECT CM.[CreditMemoHeaderId]
             ,CM.[CreditMemoNumber]
             ,CM.[RMAHeaderId]
             ,CM.[RMANumber]
             ,CM.[InvoiceId]
             ,CM.[InvoiceNumber]
             ,CM.[InvoiceDate]
             ,CM.[StatusId]
             ,CM.[Status]
             ,CM.[CustomerId]
             ,CM.[CustomerName]
             ,CM.[CustomerCode]
             ,CM.[CustomerContactId]
             ,CM.[CustomerContact]
             ,CM.[CustomerContactPhone]
             ,CM.[IsWarranty]
             ,CM.[IsAccepted]
             ,CM.[ReasonId]
	         --,CM.[Reason]
			 ,(Case When Count(SACD.CreditMemoHeaderId) > 1 Then 'Multiple' ELse CASE WHEN SACD.Reason IS NULL THEN CD.Reason ELSE SACD.Reason END End)  as 'Reason'    
			 ,SACD.Reason AS [ReasonType]
             ,CM.[DeniedMemo]
             ,CM.[RequestedById]
             ,CM.[RequestedBy]
             ,CM.[ApproverId]
             ,CM.[ApprovedBy]
             ,CM.[WONum]
             ,CM.[WorkOrderId]
             ,CM.[Originalwosonum]
             ,CM.[Memo]
             ,CM.[Notes]
             ,CM.[ManagementStructureId]
             ,CM.[IsEnforce]
             ,CM.[MasterCompanyId]
             ,CM.[CreatedBy]
             ,CM.[UpdatedBy]
             ,CM.[CreatedDate]
             ,CM.[UpdatedDate]
             ,CM.[IsActive]
             ,CM.[IsDeleted]
	         ,MS.[LastMSLevel]
             ,MS.[AllMSlevels]	
			 ,CD.[PartNumber]
			 ,CD.[PartDescription]			
			 ,CASE WHEN ABS(SUM(SACD.[Qty])) > 0 THEN SUM(SACD.[Qty]) ELSE CD.[Qty] END AS Qty
			 ,CASE WHEN SUM(SACD.[Rate]) > 0 THEN CAST(SUM(SACD.[Rate]) AS VARCHAR(200)) ELSE CAST(CD.[UnitPrice] AS VARCHAR(200)) END AS UnitPrice
			 ,CASE WHEN ABS(SUM(SACD.[Amount])) > 0 THEN SUM(SACD.[Amount]) ELSE CD.[Amount] END AS Amount
			 --,CD.[UnitPrice]
			 --,CD.[Amount]
			 ,CM.[CreatedDate] AS IssueDate
			 ,CM.[ReturnDate]
			 ,CD.[ReferenceNo]
			 ,CD.[isWorkOrder]
			 ,CD.[ReferenceId]
			 ,IM.ManufacturerName
			 ,CM.IsStandAloneCM
        FROM dbo.[CreditMemo] CM WITH (NOLOCK) 
		INNER JOIN dbo.[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON  MS.ReferenceID = CM.CreditMemoHeaderId AND MS.ModuleID = @ModuleID
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON CM.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		LEFT JOIN dbo.CreditMemoDetails CD WITH (NOLOCK)  ON CD.CreditMemoHeaderId = CM.CreditMemoHeaderId
		LEFT JOIN dbo.StandAloneCreditMemoDetails SACD WITH (NOLOCK)  ON SACD.CreditMemoHeaderId = CM.CreditMemoHeaderId AND SACD.IsActive = 1
		LEFT JOIN ItemMaster IM WITH (NOLOCK) ON CD.ItemMasterId=IM.ItemMasterId
        WHERE ((CM.MasterCompanyId = @MasterCompanyId) AND (CM.IsDeleted = @IsDeleted) 
		AND (@StatusID IS NULL OR CM.StatusId = @StatusID)) 
		GROUP BY   
		 CM.[CreditMemoHeaderId],CM.[CreditMemoNumber],CM.[RMAHeaderId],CM.[RMANumber],CM.[InvoiceId],CM.[InvoiceNumber]
             ,CM.[InvoiceDate],CM.[StatusId],CM.[Status],CM.[CustomerId],CM.[CustomerName],CM.[CustomerCode],CM.[CustomerContactId]
             ,CM.[CustomerContact],CM.[CustomerContactPhone],CM.[IsWarranty],CM.[IsAccepted],CM.[ReasonId],CD.[Reason],SACD.Reason
             ,CM.[DeniedMemo],CM.[RequestedById],CM.[RequestedBy],CM.[ApproverId],CM.[ApprovedBy],CM.[WONum],CM.[WorkOrderId]
             ,CM.[Originalwosonum],CM.[Memo],CM.[Notes],CM.[ManagementStructureId],CM.[IsEnforce],CM.[MasterCompanyId]
             ,CM.[CreatedBy],CM.[UpdatedBy],CM.[CreatedDate],CM.[UpdatedDate],CM.[IsActive],CM.[IsDeleted],MS.[LastMSLevel]
             ,MS.[AllMSlevels],CD.[PartNumber],CD.[PartDescription],CM.[CreatedDate],CM.[ReturnDate],CD.[ReferenceNo]
			 ,CD.[isWorkOrder],CD.[ReferenceId],IM.ManufacturerName,CM.IsStandAloneCM
			 ,CD.[Qty],CD.[UnitPrice], CD.[Amount]
		
        ), ResultCount AS(Select COUNT(CreditMemoHeaderId) AS totalItems FROM Result)  
        Select * INTO #TempResult from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (
		(CreditMemoNumber like '%' +@GlobalFilter+'%') OR  
		(Status like '%' +@GlobalFilter+'%') OR  
		(Reason like '%' +@GlobalFilter+'%') OR 
		(RMANumber like '%' +@GlobalFilter+'%') OR 
		(WONum like '%' +@GlobalFilter+'%') OR 
		(CustomerName like '%' +@GlobalFilter+'%') OR 
		(PartNumber like '%'+@GlobalFilter+'%') OR  
		(PartDescription like '%' +@GlobalFilter+'%') OR 
		(ManufacturerName like '%' +@GlobalFilter+'%') OR 
		(ReferenceNo like '%' +@GlobalFilter+'%') OR  
		(RequestedBy like '%' +@GlobalFilter+'%') OR  
		(LastMSLevel like '%' +@GlobalFilter+'%') OR 
		(CAST(Qty AS NVARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR	
	    (CAST(UnitPrice AS NVARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR	
		(CAST(Amount AS NVARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR	
		(Memo like '%'+@GlobalFilter+'%')))  
        OR     
        (@GlobalFilter='' AND 
		(ISNULL(@CreditMemoNumber,'') ='' OR CreditMemoNumber like '%' + @CreditMemoNumber+'%') AND 		
		(ISNULL(@IssueDate,'') ='' OR Cast(IssueDate as Date)=Cast(@IssueDate as date)) AND 
		(ISNULL(@Status,'') ='' OR Status like '%' + @Status+'%') AND  
		(ISNULL(@Reason,'') ='' OR Reason like '%' + @Reason+'%') AND 
		(ISNULL(@RMANumber,'') ='' OR RMANumber like '%' + @RMANumber+'%') AND  
		(ISNULL(@WONum,'') ='' OR WONum like '%' + @WONum+'%') AND  
		(IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
		(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
        (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND  
		(IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND  
		(IsNull(@ReferenceNo,'') ='' OR ReferenceNo like '%' + @ReferenceNo+'%') AND  
		(IsNull(@ReturnDate,'') ='' OR Cast(ReturnDate as Date)=Cast(@ReturnDate as date)) AND 
		(IsNull(CAST(@Qty AS VARCHAR(200)),'') = '' OR CAST(Qty AS varchar(200)) Like '%' +  ISNULL(CAST(@Qty AS VARCHAR(200)),'') +'%') AND  
			 (IsNull(CAST(@UnitPrice AS VARCHAR(200)),'') = '' OR CAST(UnitPrice AS varchar(200)) Like '%' +  ISNULL(CAST(@UnitPrice AS VARCHAR(200)),'') +'%') AND  
            (IsNull(CAST(@Amount AS VARCHAR(200)),'') = '' OR CAST(Amount AS varchar(200)) Like '%' +  ISNULL(CAST(@Amount AS VARCHAR(200)),'') +'%') AND   
		(ISNULL(@RequestedBy,'') ='' OR RequestedBy like '%' + @RequestedBy+'%') AND 
		(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') AND
		(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%')))  
  
        SELECT @Count = COUNT(CreditMemoHeaderId) from #TempResult     
  
        SELECT *, @Count As NumberOfItems FROM #TempResult  
        ORDER BY    

		CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMONUMBER')  THEN CreditMemoNumber END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='ISSUEDATE')  THEN IssueDate END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='REASON')  THEN Reason END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='RMANUMBER')  THEN RMANumber END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='WONUM')  THEN WONum END ASC,
		CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='ORIGINALWOSONUM')  THEN Originalwosonum END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='RETURNDATE')  THEN ReturnDate END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='UNITPRICE')  THEN UnitPrice END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT')  THEN Amount END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDBY')  THEN RequestedBy END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC, 
		CASE WHEN (@SortOrder=1 and @SortColumn='MEMO')  THEN Memo END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC, 
		CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,

		CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END Desc,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMONUMBER')  THEN CreditMemoNumber END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='ISSUEDATE')  THEN IssueDate END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='REASON')  THEN Reason END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='RMANUMBER')  THEN RMANumber END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='WONUM')  THEN WONum END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='ORIGINALWOSONUM')  THEN Originalwosonum END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='RETURNDATE')  THEN ReturnDate END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='UNITPRICE')  THEN UnitPrice END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT')  THEN Amount END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDBY')  THEN RequestedBy END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC, 
		CASE WHEN (@SortOrder=-1 and @SortColumn='MEMO')  THEN Memo END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END DESC
		  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'SearchCreditMemoData' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100))			   
			   + '@Parameter8 = ''' + CAST(ISNULL(@ReturnDate, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@PartDescription , '') AS varchar(100))			  
			   + '@Parameter12 = ''' + CAST(ISNULL(@Qty , '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@UnitPrice , '') AS varchar(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@Amount , '') AS varchar(100))				  
			   + '@Parameter15 = ''' + CAST(ISNULL(@LastMSLevel , '') AS varchar(100))
			   + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))
			   + '@Parameter17 = ''' + CAST(ISNULL(@ViewType  , '') AS varchar(100))
			   + '@Parameter18 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) 
			   + '@Parameter19 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))
			   + '@Parameter20 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100)) 
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